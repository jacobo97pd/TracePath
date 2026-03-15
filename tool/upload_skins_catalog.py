#!/usr/bin/env python3
"""Bulk upsert skins catalog in Firestore from Firebase Storage.

Usage example:
  python tool/upload_skins_catalog.py \
    --service-account C:\\keys\\firebase-admin.json \
    --bucket tracepath-e2e90.firebasestorage.app \
    --collection skins_catalog \
    --skins-prefix skins/ \
    --cards-prefix cards/ \
    --overrides-json tool/skins_catalog_overrides.sample.json
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore, storage

IMAGE_EXTS = (".png", ".jpg", ".jpeg", ".webp")


@dataclass(frozen=True)
class SkinItem:
    skin_id: str
    image_path: str
    image_name: str


def _normalize_id(stem: str) -> str:
    value = stem.strip().lower().replace("_", "-").replace(" ", "-")
    value = re.sub(r"-{2,}", "-", value)
    return value.strip("-")


def _title_from_id(skin_id: str) -> str:
    parts = [p for p in skin_id.split("-") if p]
    return " ".join(p.capitalize() for p in parts) or "Skin"


def _list_storage_images(bucket: storage.bucket, prefix: str) -> list[SkinItem]:
    items: list[SkinItem] = []
    for blob in bucket.list_blobs(prefix=prefix):
        name = blob.name
        if name.endswith("/") or not name.lower().endswith(IMAGE_EXTS):
            continue
        filename = Path(name).name
        stem = Path(filename).stem
        skin_id = _normalize_id(stem)
        items.append(SkinItem(skin_id=skin_id, image_path=name, image_name=filename))
    items.sort(key=lambda it: it.skin_id)
    return items


def _build_card_index(bucket: storage.bucket, prefix: str) -> dict[str, str]:
    index: dict[str, str] = {}
    for blob in bucket.list_blobs(prefix=prefix):
        name = blob.name
        if name.endswith("/") or not name.lower().endswith(IMAGE_EXTS):
            continue
        stem = _normalize_id(Path(name).stem)
        index[stem] = name
    return index


def _build_thumb_index(bucket: storage.bucket, prefix: str) -> dict[str, str]:
    index: dict[str, str] = {}
    for blob in bucket.list_blobs(prefix=prefix):
        name = blob.name
        if name.endswith("/") or not name.lower().endswith(IMAGE_EXTS):
            continue
        stem = _normalize_id(Path(name).stem)
        stem = re.sub(r"[-_]?thumb$", "", stem)
        if stem:
            index[stem] = name
    return index


def _resolve_card_path(skin_id: str, card_index: dict[str, str]) -> str:
    candidates = (
        f"{skin_id}-tarjeta",
        f"tarjeta-{skin_id}",
        f"{skin_id}-card",
        f"card-{skin_id}",
        skin_id,
    )
    for key in candidates:
        if key in card_index:
            return card_index[key]
    return ""


def _load_overrides(path: str | None) -> dict[str, dict[str, Any]]:
    if not path:
        return {}
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Overrides JSON must be an object: {skin_id: {...}}")
    out: dict[str, dict[str, Any]] = {}
    for key, value in data.items():
        if isinstance(value, dict):
            out[_normalize_id(str(key))] = value
    return out


def _build_doc(
    item: SkinItem,
    order: int,
    card_path: str,
    thumb_path: str,
    overrides: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    ov = overrides.get(item.skin_id, {})
    name = str(ov.get("name", _title_from_id(item.skin_id)))
    price = int(ov.get("price", 300))
    rarity = str(ov.get("rarity", "Common"))
    enabled = bool(ov.get("enabled", True))
    explicit_order = ov.get("order")
    if explicit_order is not None:
        order = int(explicit_order)
    explicit_card = ov.get("cardPath")
    if isinstance(explicit_card, str) and explicit_card.strip():
        card_path = explicit_card.strip()
    explicit_thumb = ov.get("thumbPath")
    if isinstance(explicit_thumb, str) and explicit_thumb.strip():
        thumb_path = explicit_thumb.strip()
    return {
        "name": name,
        "price": price,
        "rarity": rarity,
        "enabled": enabled,
        "order": order,
        "imagePath": item.image_path,
        "thumbPath": thumb_path,
        "cardPath": card_path,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }


def run(args: argparse.Namespace) -> None:
    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred, {"storageBucket": args.bucket})
    db = firestore.client(database_id=args.database_id)
    bucket = storage.bucket()

    overrides = _load_overrides(args.overrides_json)
    skins = _list_storage_images(bucket, args.skins_prefix)
    cards = _build_card_index(bucket, args.cards_prefix)
    thumbs = _build_thumb_index(bucket, args.thumbs_prefix)

    if not skins:
        raise RuntimeError(
            f"No images found in storage prefix '{args.skins_prefix}'. "
            "Check bucket name and prefix."
        )

    print(f"[INFO] skins found: {len(skins)}")
    print(f"[INFO] cards found: {len(cards)}")
    print(f"[INFO] thumbs found: {len(thumbs)}")

    batch = db.batch()
    written = 0
    for i, item in enumerate(skins, start=1):
        card_path = _resolve_card_path(item.skin_id, cards)
        thumb_path = thumbs.get(item.skin_id, "")
        doc = _build_doc(
            item,
            order=i,
            card_path=card_path,
            thumb_path=thumb_path,
            overrides=overrides,
        )
        doc_ref = db.collection(args.collection).document(item.skin_id)
        batch.set(doc_ref, doc, merge=True)
        written += 1
        if written % 400 == 0:
            if not args.dry_run:
                batch.commit()
            batch = db.batch()

    if not args.dry_run:
        batch.commit()
    print(f"[OK] {'Prepared' if args.dry_run else 'Upserted'} docs: {written}")
    print(f"[OK] collection: {args.collection}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True, help="Path to admin SDK JSON")
    parser.add_argument("--bucket", required=True, help="Firebase storage bucket")
    parser.add_argument("--collection", default="skins_catalog")
    parser.add_argument(
        "--database-id",
        default="(default)",
        help="Firestore database id (e.g. '(default)' or 'tracepath-database')",
    )
    parser.add_argument("--skins-prefix", default="skins/")
    parser.add_argument("--cards-prefix", default="cards/")
    parser.add_argument("--thumbs-prefix", default="skins_thumb/")
    parser.add_argument("--overrides-json", default=None)
    parser.add_argument("--dry-run", action="store_true")
    run(parser.parse_args())


if __name__ == "__main__":
    main()
