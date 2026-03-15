#!/usr/bin/env python3
"""Copy legacy skin media objects to v2 layout in Firebase Storage.

v2 layout target:
  skins/<skin_id>/full.<ext>
  skins/<skin_id>/preview.<ext>
  skins/<skin_id>/icon.<ext>
  skins/<skin_id>/banner.<ext>

Legacy sources considered:
  imagePath / image
  thumbPath / thumbnailPath
  cardPath
  and common folder conventions:
    skins/
    skins_low_renders/
    skins_thumb/
    banner_skin_compra/

Usage example:
  python tool/migrate_skins_storage_to_v2.py ^
    --service-account "C:\\path\\adminsdk.json" ^
    --bucket tracepath-e2e90.firebasestorage.app ^
    --database-id tracepath-database ^
    --collection skins_catalog ^
    --dry-run
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

import firebase_admin
from firebase_admin import credentials, firestore, storage

IMAGE_EXTS = (".webp", ".png", ".jpg", ".jpeg")
FULL_CANDIDATE_EXTS = (".png", ".webp", ".jpg", ".jpeg")
PREVIEW_CANDIDATE_EXTS = (".webp", ".png", ".jpg", ".jpeg")
ICON_CANDIDATE_EXTS = (".webp", ".png", ".jpg", ".jpeg")
BANNER_CANDIDATE_EXTS = (".webp", ".jpg", ".png", ".jpeg")
POINTER_DEFAULT = "pointer_default"


@dataclass
class RoleResult:
    role: str
    source: str
    target: str
    action: str
    error: str | None


@dataclass
class SkinResult:
    skin_id: str
    results: list[RoleResult]


def _normalize_object_path(raw: str, bucket: str) -> str:
    value = raw.strip()
    if not value:
        return ""
    if value.startswith("gs://"):
        without = value.removeprefix("gs://")
        slash = without.find("/")
        if slash <= 0:
            return ""
        b = without[:slash]
        return without[slash + 1 :] if b == bucket else ""
    if value.startswith("http://") or value.startswith("https://"):
        try:
            parsed = urlparse(value)
            parts = parsed.path.split("/")
            if "o" in parts:
                idx = parts.index("o")
                encoded = "/".join(parts[idx + 1 :]).strip()
                return unquote(encoded) if encoded else ""
        except Exception:
            return ""
        return ""
    return value.replace("\\", "/")


def _basename_no_ext(path: str) -> str:
    name = Path(path).name
    if not name:
        return ""
    stem = Path(name).stem
    if stem.endswith("-thumb"):
        stem = stem[: -len("-thumb")]
    return stem


def _ext(path: str, fallback: str) -> str:
    suffix = Path(path).suffix.lower()
    if suffix in IMAGE_EXTS:
        return suffix
    return fallback


def _first_existing(bucket_obj: storage.bucket, candidates: list[str]) -> str:
    seen: set[str] = set()
    for raw in candidates:
        candidate = raw.strip().replace("\\", "/")
        if not candidate or candidate in seen:
            continue
        seen.add(candidate)
        if bucket_obj.blob(candidate).exists():
            return candidate
    return ""


def _base_names_for_skin(skin_id: str, data: dict[str, Any], bucket: str) -> list[str]:
    out: list[str] = []

    def add(value: str) -> None:
        v = value.strip()
        if v and v not in out:
            out.append(v)

    image_map = data.get("image")
    image_data = image_map if isinstance(image_map, dict) else {}
    raw_candidates = [
        str(image_data.get("fullPath", "") or ""),
        str(image_data.get("previewPath", "") or ""),
        str(data.get("imagePath", "") or ""),
        str(data.get("thumbPath", "") or ""),
        str(data.get("thumbnailPath", "") or ""),
    ]
    for raw in raw_candidates:
        obj = _normalize_object_path(raw, bucket)
        base = _basename_no_ext(obj) if obj else ""
        add(base)

    id_base = skin_id.strip().replace("_", "-")
    add(id_base)
    if "old-man" in id_base:
        add(id_base.replace("old-man", "oldman"))
    if "oldman" in id_base:
        add(id_base.replace("oldman", "old-man"))
    return out


def _build_candidates(
    *,
    role: str,
    data: dict[str, Any],
    bucket: str,
    base_names: list[str],
) -> list[str]:
    image_map = data.get("image")
    image_data = image_map if isinstance(image_map, dict) else {}
    out: list[str] = []

    def add_raw(value: str) -> None:
        obj = _normalize_object_path(value, bucket)
        if obj:
            out.append(obj)

    if role == "full":
        add_raw(str(image_data.get("fullPath", "") or ""))
        add_raw(str(data.get("imagePath", "") or ""))
        add_raw(str(data.get("image", "") or ""))
        for base in base_names:
            for ext in FULL_CANDIDATE_EXTS:
                out.append(f"skins/{base}{ext}")
    elif role == "preview":
        add_raw(str(image_data.get("previewPath", "") or ""))
        add_raw(str(data.get("thumbPath", "") or ""))
        add_raw(str(data.get("thumbnailPath", "") or ""))
        for base in base_names:
            for ext in PREVIEW_CANDIDATE_EXTS:
                out.append(f"skins_low_renders/{base}{ext}")
    elif role == "icon":
        add_raw(str(image_data.get("iconPath", "") or ""))
        add_raw(str(data.get("thumbPath", "") or ""))
        add_raw(str(data.get("thumbnailPath", "") or ""))
        for base in base_names:
            for ext in ICON_CANDIDATE_EXTS:
                out.append(f"skins_thumb/{base}-thumb{ext}")
    elif role == "banner":
        add_raw(str(image_data.get("bannerPath", "") or ""))
        add_raw(str(data.get("cardPath", "") or ""))
        for base in base_names:
            for ext in BANNER_CANDIDATE_EXTS:
                out.append(f"banner_skin_compra/{base}-banner{ext}")
    return out


def _copy_role(
    *,
    bucket_obj: storage.bucket,
    skin_id: str,
    role: str,
    source: str,
    dst_root: str,
    overwrite: bool,
    dry_run: bool,
) -> RoleResult:
    if not source:
        return RoleResult(role=role, source="", target="", action="missing_source", error=None)

    default_ext = ".png" if role == "full" else ".webp"
    extension = _ext(source, default_ext)
    target = f"{dst_root}/{skin_id}/{role}{extension}"

    if source == target:
        return RoleResult(role=role, source=source, target=target, action="already_v2", error=None)

    dst_blob = bucket_obj.blob(target)
    if dst_blob.exists() and not overwrite:
        return RoleResult(role=role, source=source, target=target, action="target_exists", error=None)

    if dry_run:
        action = "would_overwrite" if dst_blob.exists() else "would_copy"
        return RoleResult(role=role, source=source, target=target, action=action, error=None)

    try:
        src_blob = bucket_obj.blob(source)
        if not src_blob.exists():
            return RoleResult(
                role=role,
                source=source,
                target=target,
                action="missing_source",
                error="source blob does not exist",
            )
        bucket_obj.copy_blob(src_blob, bucket_obj, target)
        copied = bucket_obj.blob(target)
        copied.cache_control = "public,max-age=31536000,immutable"
        copied.patch()
        action = "overwritten" if dst_blob.exists() else "copied"
        return RoleResult(role=role, source=source, target=target, action=action, error=None)
    except Exception as exc:  # noqa: BLE001
        return RoleResult(role=role, source=source, target=target, action="error", error=str(exc))


def run(args: argparse.Namespace) -> int:
    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred, {"storageBucket": args.bucket})
    db = firestore.client(database_id=args.database_id)
    bucket_obj = storage.bucket()

    dst_root = args.dst_root.strip().replace("\\", "/").strip("/")
    if not dst_root:
        raise RuntimeError("--dst-root must not be empty")

    snap = db.collection(args.collection).get()
    docs = list(snap)
    if args.limit and args.limit > 0:
        docs = docs[: args.limit]

    print(f"[INFO] docs considered: {len(docs)}")
    results: list[SkinResult] = []
    counters = {
        "copied": 0,
        "overwritten": 0,
        "target_exists": 0,
        "already_v2": 0,
        "missing_source": 0,
        "error": 0,
        "would_copy": 0,
        "would_overwrite": 0,
    }

    for doc in docs:
        skin_id = doc.id.strip()
        if not skin_id or skin_id == POINTER_DEFAULT:
            continue
        data = doc.to_dict() or {}
        base_names = _base_names_for_skin(skin_id, data, args.bucket)

        role_results: list[RoleResult] = []
        for role in ("full", "preview", "icon", "banner"):
            candidates = _build_candidates(
                role=role,
                data=data,
                bucket=args.bucket,
                base_names=base_names,
            )
            source = _first_existing(bucket_obj, candidates)
            result = _copy_role(
                bucket_obj=bucket_obj,
                skin_id=skin_id,
                role=role,
                source=source,
                dst_root=dst_root,
                overwrite=args.overwrite,
                dry_run=args.dry_run,
            )
            role_results.append(result)
            counters[result.action] = counters.get(result.action, 0) + 1
            if result.action in {"error", "missing_source"}:
                print(
                    f"[WARN] {skin_id}.{role} action={result.action} "
                    f"source={result.source or '-'} target={result.target or '-'}"
                )

        results.append(SkinResult(skin_id=skin_id, results=role_results))

    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "bucket": args.bucket,
        "databaseId": args.database_id,
        "collection": args.collection,
        "dstRoot": dst_root,
        "dryRun": args.dry_run,
        "overwrite": args.overwrite,
        "summary": counters,
        "skins": [
            {
                "skinId": skin.skin_id,
                "results": [asdict(r) for r in skin.results],
            }
            for skin in results
        ],
    }

    out = Path(args.out_json)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] report: {out}")
    print(f"[OK] summary: {json.dumps(counters, ensure_ascii=False)}")

    return 1 if counters.get("error", 0) > 0 else 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--bucket", default="tracepath-e2e90.firebasestorage.app")
    parser.add_argument("--database-id", default="tracepath-database")
    parser.add_argument("--collection", default="skins_catalog")
    parser.add_argument("--dst-root", default="skins")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--out-json",
        default="verify_output/storage_migration_v2_report.json",
    )
    code = run(parser.parse_args())
    raise SystemExit(code)


if __name__ == "__main__":
    main()
