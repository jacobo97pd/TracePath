#!/usr/bin/env python3
"""Delete legacy Firebase Storage objects for skins migration.

Legacy prefixes targeted by default:
  skins_low_renders/
  skins_thumb/
  banner_skin_compra/

Safety:
  - Does NOT touch `skins/` unless you explicitly pass that prefix.
  - Supports dry-run mode (recommended first).

Usage:
  # Preview only
  python tool/delete_legacy_storage_objects.py ^
    --service-account "C:\\path\\adminsdk.json" ^
    --bucket tracepath-e2e90.firebasestorage.app ^
    --dry-run

  # Real delete
  python tool/delete_legacy_storage_objects.py ^
    --service-account "C:\\path\\adminsdk.json" ^
    --bucket tracepath-e2e90.firebasestorage.app
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, storage

DEFAULT_PREFIXES = (
    "skins_low_renders/",
    "skins_thumb/",
    "banner_skin_compra/",
)


def _normalize_prefix(value: str) -> str:
    prefix = value.strip().replace("\\", "/")
    if not prefix:
        return ""
    if not prefix.endswith("/"):
        prefix = f"{prefix}/"
    return prefix


def run(args: argparse.Namespace) -> int:
    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred, {"storageBucket": args.bucket})
    bucket = storage.bucket()

    raw_prefixes = args.prefix if args.prefix else list(DEFAULT_PREFIXES)
    prefixes = []
    for raw in raw_prefixes:
        p = _normalize_prefix(raw)
        if not p:
            continue
        prefixes.append(p)

    prefixes = sorted(set(prefixes))
    if not prefixes:
        raise RuntimeError("No prefixes to process")

    objects: list[str] = []
    for prefix in prefixes:
        for blob in bucket.list_blobs(prefix=prefix):
            if blob.name.endswith("/"):
                continue
            objects.append(blob.name)

    objects = sorted(set(objects))
    if args.limit and args.limit > 0:
        objects = objects[: args.limit]

    deleted = 0
    failed = 0
    failures: list[dict[str, str]] = []

    for name in objects:
        if args.dry_run:
            print(f"[DRY] {name}")
            continue
        try:
            bucket.blob(name).delete()
            deleted += 1
        except Exception as exc:  # noqa: BLE001
            failed += 1
            failures.append({"name": name, "error": str(exc)})
            print(f"[FAIL] {name} -> {exc}")

    summary = {
        "dryRun": args.dry_run,
        "bucket": args.bucket,
        "prefixes": prefixes,
        "found": len(objects),
        "deleted": deleted,
        "failed": failed,
    }
    report = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "summary": summary,
        "objects": objects,
        "failures": failures,
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
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--prefix", action="append", default=[])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument(
        "--out-json",
        default="verify_output/delete_legacy_storage_objects_report.json",
    )
    code = run(parser.parse_args())
    raise SystemExit(code)


if __name__ == "__main__":
    main()
