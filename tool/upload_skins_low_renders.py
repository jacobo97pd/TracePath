#!/usr/bin/env python3
"""Upload low-render skin previews to Firebase Storage.

Default target:
  local folder:   C:\\tracepath_server\\skins_low_renders
  storage prefix: skins_low_renders/

Example:
  python tool/upload_skins_low_renders.py ^
    --service-account "C:\\Users\\jacob\\Documents\\tracepath-e2e90-firebase-adminsdk-fbsvc-67d8fb976a.json"
"""

from __future__ import annotations

import argparse
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, storage

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}
DEFAULT_LOCAL_DIR = r"C:\tracepath_server\skins_low_renders"
DEFAULT_BUCKET = "tracepath-e2e90.firebasestorage.app"
DEFAULT_PREFIX = "skins_low_renders/"


def run(args: argparse.Namespace) -> None:
    local_dir = Path(args.local_dir)
    if not local_dir.exists() or not local_dir.is_dir():
        raise RuntimeError(f"Local directory not found: {local_dir}")

    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred, {"storageBucket": args.bucket})
    bucket = storage.bucket()

    prefix = args.storage_prefix.strip().replace("\\", "/")
    if prefix and not prefix.endswith("/"):
        prefix = f"{prefix}/"

    files = [
        p
        for p in local_dir.rglob("*")
        if p.is_file() and p.suffix.lower() in IMAGE_EXTS
    ]
    files.sort()
    if not files:
        print("[INFO] no image files found")
        return

    uploaded = 0
    skipped = 0
    for path in files:
        rel = path.relative_to(local_dir).as_posix()
        remote_name = f"{prefix}{rel}"
        blob = bucket.blob(remote_name)

        if args.skip_existing and blob.exists():
            skipped += 1
            continue

        if args.dry_run:
            print(f"[DRY] {path} -> {remote_name}")
            uploaded += 1
            continue

        blob.upload_from_filename(str(path))
        blob.cache_control = "public,max-age=31536000,immutable"
        blob.patch()
        uploaded += 1

    if args.dry_run:
        print(f"[OK] would upload: {uploaded} (skipped existing: {skipped})")
    else:
        print(f"[OK] uploaded: {uploaded} (skipped existing: {skipped})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--bucket", default=DEFAULT_BUCKET)
    parser.add_argument("--local-dir", default=DEFAULT_LOCAL_DIR)
    parser.add_argument("--storage-prefix", default=DEFAULT_PREFIX)
    parser.add_argument("--skip-existing", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    run(parser.parse_args())


if __name__ == "__main__":
    main()

