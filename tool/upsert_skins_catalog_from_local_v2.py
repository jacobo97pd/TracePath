#!/usr/bin/env python3
"""Validate local skin folders and upsert Firestore skins_catalog with v2 paths.

Expected local layout:
  <local_root>/<skin_id>/<skin_id>.png|webp|jpg|jpeg
  <local_root>/<skin_id>/<skin_id>-thumb.png|webp|jpg|jpeg
  <local_root>/<skin_id>/<skin_id>-banner.webp|png|jpg|jpeg
  <local_root>/<skin_id>/<skin_id>-tarjeta.png|webp|jpg|jpeg   (optional)

Storage object paths written to Firestore assume upload with:
  --local-dir <local_root> --storage-prefix skins/
So files become:
  skins/<skin_id>/<filename>

Usage:
  python tool/upsert_skins_catalog_from_local_v2.py ^
    --service-account "C:\\path\\adminsdk.json" ^
    --database-id tracepath-database ^
    --collection skins_catalog ^
    --local-root "C:\\tracepath_server\\skins" ^
    --storage-prefix "skins/" ^
    --dry-run
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore

IMAGE_EXTS = (".png", ".webp", ".jpg", ".jpeg")
POINTER_DEFAULT = "default"


@dataclass
class SkinLocalFiles:
    skin_id: str
    full_name: str
    thumb_name: str
    banner_name: str
    card_name: str


@dataclass
class UpsertResult:
    skin_id: str
    action: str
    reason: str
    image: dict[str, str]
    cardPath: str


def _first_match(folder: Path, candidates: list[str]) -> str:
    for name in candidates:
        if (folder / name).is_file():
            return name
    return ""


def _find_local_files(folder: Path) -> SkinLocalFiles | None:
    skin_id = folder.name.strip()
    if not skin_id:
        return None

    full = _first_match(folder, [f"{skin_id}{ext}" for ext in IMAGE_EXTS])
    thumb = _first_match(folder, [f"{skin_id}-thumb{ext}" for ext in IMAGE_EXTS])
    banner = _first_match(folder, [f"{skin_id}-banner{ext}" for ext in IMAGE_EXTS])
    card = _first_match(folder, [f"{skin_id}-tarjeta{ext}" for ext in IMAGE_EXTS])

    if not full or not thumb or not banner:
        return None
    return SkinLocalFiles(
        skin_id=skin_id,
        full_name=full,
        thumb_name=thumb,
        banner_name=banner,
        card_name=card,
    )


def _human_name(skin_id: str) -> str:
    parts = [p for p in skin_id.split("-") if p]
    return " ".join(p.capitalize() for p in parts) if parts else "Skin"


def _image_map(storage_prefix: str, files: SkinLocalFiles) -> dict[str, str]:
    root = storage_prefix.strip().replace("\\", "/")
    if root and not root.endswith("/"):
        root = f"{root}/"
    base = f"{root}{files.skin_id}/"
    full = f"{base}{files.full_name}"
    preview = f"{base}{files.thumb_name}"
    icon = preview
    banner = f"{base}{files.banner_name}"
    return {
        "fullPath": full,
        "previewPath": preview,
        "iconPath": icon,
        "bannerPath": banner,
    }


def _same_image(a: Any, b: dict[str, str]) -> bool:
    if not isinstance(a, dict):
        return False
    return (
        str(a.get("fullPath", "") or "") == b["fullPath"]
        and str(a.get("previewPath", "") or "") == b["previewPath"]
        and str(a.get("iconPath", "") or "") == b["iconPath"]
        and str(a.get("bannerPath", "") or "") == b["bannerPath"]
    )


def run(args: argparse.Namespace) -> int:
    local_root = Path(args.local_root)
    if not local_root.exists() or not local_root.is_dir():
        raise RuntimeError(f"Local root not found or not a directory: {local_root}")

    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred)
    db = firestore.client(database_id=args.database_id)

    snap = db.collection(args.collection).get()
    existing: dict[str, dict[str, Any]] = {doc.id: (doc.to_dict() or {}) for doc in snap}

    folders = [p for p in local_root.iterdir() if p.is_dir()]
    folders.sort(key=lambda p: p.name.lower())

    valid: list[SkinLocalFiles] = []
    errors: list[str] = []
    for folder in folders:
        item = _find_local_files(folder)
        if item is None:
            errors.append(f"{folder.name}: missing full/thumb/banner with expected naming")
            continue
        valid.append(item)

    if errors:
        print(f"[WARN] local validation issues: {len(errors)}")
        for line in errors[:50]:
            print(f"[WARN] {line}")
        if args.strict:
            raise RuntimeError("Validation failed and --strict enabled")

    ordered_existing_orders = [
        int((data.get("order", 0) or 0))
        for data in existing.values()
        if isinstance(data.get("order"), (int, float))
    ]
    next_order = (max(ordered_existing_orders) + 1) if ordered_existing_orders else 1

    to_write: list[tuple[firestore.DocumentReference, dict[str, Any]]] = []
    results: list[UpsertResult] = []
    changed = 0
    unchanged = 0

    for item in valid:
        doc_id = item.skin_id
        current = existing.get(doc_id, {})
        image = _image_map(args.storage_prefix, item)
        card_path = (
            f"{args.storage_prefix.rstrip('/').replace('\\', '/')}/{item.skin_id}/{item.card_name}"
            if item.card_name
            else ""
        )

        price = int(current.get("price", current.get("costCoins", 300)) or 300)
        rarity = str(current.get("rarity", "Common") or "Common")
        enabled = bool(current.get("enabled", True))
        order = int(current.get("order", 0) or 0)
        if order <= 0:
            order = next_order
            next_order += 1

        name = str(current.get("name", _human_name(doc_id)) or _human_name(doc_id))

        current_image = current.get("image")
        current_card = str(current.get("cardPath", "") or "")
        same = (
            _same_image(current_image, image)
            and current_card == card_path
            and int(current.get("schemaVersion", 0) or 0) >= 2
        )

        payload: dict[str, Any] = {
            "name": name,
            "price": price,
            "rarity": rarity,
            "enabled": enabled,
            "order": order,
            "image": image,
            "imagePath": image["fullPath"],
            "thumbPath": image["previewPath"],
            "thumbnailPath": image["previewPath"],
            "cardPath": card_path,
            "schemaVersion": 2,
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "migratedAt": firestore.SERVER_TIMESTAMP,
        }

        action = "unchanged"
        reason = "already_up_to_date"
        if not same:
            changed += 1
            action = "would_update" if args.dry_run else ("create" if doc_id not in existing else "update")
            reason = "paths_or_schema_changed"
            to_write.append((db.collection(args.collection).document(doc_id), payload))
        else:
            unchanged += 1

        results.append(
            UpsertResult(
                skin_id=doc_id,
                action=action,
                reason=reason,
                image=image,
                cardPath=card_path,
            )
        )

    if not args.dry_run and to_write:
        batch = db.batch()
        count = 0
        for ref, payload in to_write:
            batch.set(ref, payload, merge=True)
            count += 1
            if count % 400 == 0:
                batch.commit()
                batch = db.batch()
        if count % 400 != 0:
            batch.commit()

    summary = {
        "foldersFound": len(folders),
        "validFolders": len(valid),
        "validationErrors": len(errors),
        "changed": changed,
        "unchanged": unchanged,
        "dryRun": args.dry_run,
    }
    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "databaseId": args.database_id,
        "collection": args.collection,
        "localRoot": str(local_root),
        "storagePrefix": args.storage_prefix,
        "summary": summary,
        "errors": errors,
        "docs": [asdict(r) for r in results],
    }
    out = Path(args.out_json)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] report: {out}")
    print(f"[OK] summary: {json.dumps(summary, ensure_ascii=False)}")
    return 1 if errors and args.strict else 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--database-id", default="tracepath-database")
    parser.add_argument("--collection", default="skins_catalog")
    parser.add_argument("--local-root", default=r"C:\tracepath_server\skins")
    parser.add_argument("--storage-prefix", default="skins/")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument(
        "--out-json",
        default="verify_output/upsert_catalog_from_local_v2_report.json",
    )
    code = run(parser.parse_args())
    raise SystemExit(code)


if __name__ == "__main__":
    main()
