#!/usr/bin/env python3
"""Upsert v2 image fields in Firestore skins catalog.

Writes, per doc:
  image.fullPath
  image.previewPath
  image.iconPath
  image.bannerPath
  schemaVersion = 2
  migratedAt = SERVER_TIMESTAMP

Legacy fields remain untouched for temporary compatibility.

Usage example:
  python tool/migrate_firestore_catalog_to_v2.py ^
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
PREFERRED_EXTS = (".webp", ".png", ".jpg", ".jpeg")
POINTER_DEFAULT = "pointer_default"


@dataclass
class DocResult:
    skin_id: str
    changed: bool
    image: dict[str, str]
    reason: str


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


def _preferred_existing_under_v2(
    bucket_obj: storage.bucket,
    skin_id: str,
    role: str,
    dst_root: str,
) -> str:
    candidates = [f"{dst_root}/{skin_id}/{role}{ext}" for ext in PREFERRED_EXTS]
    return _first_existing(bucket_obj, candidates)


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
        if obj:
            add(_basename_no_ext(obj))

    id_base = skin_id.strip().replace("_", "-")
    add(id_base)
    if "old-man" in id_base:
        add(id_base.replace("old-man", "oldman"))
    if "oldman" in id_base:
        add(id_base.replace("oldman", "old-man"))
    return out


def _legacy_candidates(
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
            for ext in (".png", ".webp", ".jpg", ".jpeg"):
                out.append(f"skins/{base}{ext}")
    elif role == "preview":
        add_raw(str(image_data.get("previewPath", "") or ""))
        add_raw(str(data.get("thumbPath", "") or ""))
        add_raw(str(data.get("thumbnailPath", "") or ""))
        for base in base_names:
            for ext in (".webp", ".png", ".jpg", ".jpeg"):
                out.append(f"skins_low_renders/{base}{ext}")
    elif role == "icon":
        add_raw(str(image_data.get("iconPath", "") or ""))
        add_raw(str(data.get("thumbPath", "") or ""))
        add_raw(str(data.get("thumbnailPath", "") or ""))
        for base in base_names:
            for ext in (".webp", ".png", ".jpg", ".jpeg"):
                out.append(f"skins_thumb/{base}-thumb{ext}")
    elif role == "banner":
        add_raw(str(image_data.get("bannerPath", "") or ""))
        add_raw(str(data.get("cardPath", "") or ""))
        for base in base_names:
            for ext in (".webp", ".jpg", ".png", ".jpeg"):
                out.append(f"banner_skin_compra/{base}-banner{ext}")
    return out


def _same_image_map(a: dict[str, Any], b: dict[str, str]) -> bool:
    return (
        str(a.get("fullPath", "") or "") == b["fullPath"]
        and str(a.get("previewPath", "") or "") == b["previewPath"]
        and str(a.get("iconPath", "") or "") == b["iconPath"]
        and str(a.get("bannerPath", "") or "") == b["bannerPath"]
    )


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
    changed = 0
    unchanged = 0
    failed = 0
    results: list[DocResult] = []

    batch = db.batch()
    in_batch = 0

    for doc in docs:
        skin_id = doc.id.strip()
        if not skin_id or skin_id == POINTER_DEFAULT:
            continue
        data = doc.to_dict() or {}
        base_names = _base_names_for_skin(skin_id, data, args.bucket)

        full = _preferred_existing_under_v2(bucket_obj, skin_id, "full", dst_root)
        preview = _preferred_existing_under_v2(bucket_obj, skin_id, "preview", dst_root)
        icon = _preferred_existing_under_v2(bucket_obj, skin_id, "icon", dst_root)
        banner = _preferred_existing_under_v2(bucket_obj, skin_id, "banner", dst_root)

        if not full:
            full = _first_existing(
                bucket_obj,
                _legacy_candidates("full", data, args.bucket, base_names),
            )
        if not preview:
            preview = _first_existing(
                bucket_obj,
                _legacy_candidates("preview", data, args.bucket, base_names),
            )
        if not icon:
            icon = _first_existing(
                bucket_obj,
                _legacy_candidates("icon", data, args.bucket, base_names),
            )
        if not banner:
            banner = _first_existing(
                bucket_obj,
                _legacy_candidates("banner", data, args.bucket, base_names),
            )

        next_image = {
            "fullPath": full,
            "previewPath": preview,
            "iconPath": icon,
            "bannerPath": banner,
        }
        current_image_raw = data.get("image")
        current_image = current_image_raw if isinstance(current_image_raw, dict) else {}
        doc_changed = not _same_image_map(current_image, next_image) or int(
            data.get("schemaVersion", 0) or 0
        ) < 2

        if doc_changed:
            changed += 1
            payload = {
                "image": next_image,
                "schemaVersion": 2,
                "migratedAt": firestore.SERVER_TIMESTAMP,
            }
            if not args.dry_run:
                try:
                    batch.set(doc.reference, payload, merge=True)
                    in_batch += 1
                    if in_batch >= 400:
                        batch.commit()
                        batch = db.batch()
                        in_batch = 0
                except Exception as exc:  # noqa: BLE001
                    failed += 1
                    results.append(
                        DocResult(
                            skin_id=skin_id,
                            changed=False,
                            image=next_image,
                            reason=f"write_error: {exc}",
                        )
                    )
                    continue
            results.append(
                DocResult(
                    skin_id=skin_id,
                    changed=True,
                    image=next_image,
                    reason="updated" if not args.dry_run else "would_update",
                )
            )
        else:
            unchanged += 1
            results.append(
                DocResult(
                    skin_id=skin_id,
                    changed=False,
                    image=next_image,
                    reason="unchanged",
                )
            )

    if not args.dry_run and in_batch > 0:
        batch.commit()

    summary = {
        "changed": changed,
        "unchanged": unchanged,
        "failed": failed,
    }
    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "bucket": args.bucket,
        "databaseId": args.database_id,
        "collection": args.collection,
        "dstRoot": dst_root,
        "dryRun": args.dry_run,
        "summary": summary,
        "docs": [asdict(r) for r in results],
    }
    out = Path(args.out_json)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] report: {out}")
    print(f"[OK] summary: {json.dumps(summary, ensure_ascii=False)}")
    return 1 if failed > 0 else 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--bucket", default="tracepath-e2e90.firebasestorage.app")
    parser.add_argument("--database-id", default="tracepath-database")
    parser.add_argument("--collection", default="skins_catalog")
    parser.add_argument("--dst-root", default="skins")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--out-json",
        default="verify_output/firestore_catalog_migration_v2_report.json",
    )
    code = run(parser.parse_args())
    raise SystemExit(code)


if __name__ == "__main__":
    main()
