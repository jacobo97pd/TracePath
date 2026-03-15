#!/usr/bin/env python3
"""Upload a local folder to Firebase Storage prefix.

Example:
  python tool/upload_folder_to_storage.py \
    --service-account C:\\path\\adminsdk.json \
    --bucket tracepath-e2e90.firebasestorage.app \
    --local-dir C:\\Users\\jacob\\Documents\\skins_thumb \
    --storage-prefix skins_thumb/
"""

from __future__ import annotations

import argparse
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, storage

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


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
    for path in files:
        rel = path.relative_to(local_dir).as_posix()
        remote_name = f"{prefix}{rel}"
        blob = bucket.blob(remote_name)
        if args.skip_existing and blob.exists():
            continue
        if args.dry_run:
            print(f"[DRY] {path} -> {remote_name}")
            uploaded += 1
            continue
        blob.upload_from_filename(str(path))
        blob.cache_control = "public,max-age=31536000"
        blob.patch()
        uploaded += 1

    print(f"[OK] {'would upload' if args.dry_run else 'uploaded'} files: {uploaded}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--local-dir", required=True)
    parser.add_argument("--storage-prefix", required=True)
    parser.add_argument("--skip-existing", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    run(parser.parse_args())


if __name__ == "__main__":
    main()
