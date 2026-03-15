#!/usr/bin/env python3
"""Validate skin/media paths from Firestore skins_catalog.

Checks each doc field (imagePath/thumbPath/cardPath):
1) Object existence in Firebase Storage via Admin SDK.
2) Public media URL response (HTTP GET).

Usage:
  python tool/check_skin_urls.py ^
    --service-account C:\\path\\adminsdk.json ^
    --bucket tracepath-e2e90.firebasestorage.app ^
    --database-id tracepath-database ^
    --collection skins_catalog
"""

from __future__ import annotations

import argparse
import json
import urllib.parse
import urllib.request
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore, storage


@dataclass
class UrlCheck:
    field: str
    raw: str
    object_path: str
    admin_exists: bool | None
    public_url: str
    http_status: int | None
    http_ok: bool
    error: str | None


def _object_path_from_raw(raw: str, bucket: str) -> str:
    value = raw.strip()
    if not value:
        return ""
    if value.startswith("gs://"):
        without = value.removeprefix("gs://")
        slash = without.find("/")
        if slash < 0:
            return ""
        b = without[:slash]
        if b != bucket:
            return ""
        return without[slash + 1 :]
    if value.startswith("http://") or value.startswith("https://"):
        try:
            parsed = urllib.parse.urlparse(value)
            # /v0/b/<bucket>/o/<encoded_path>
            parts = parsed.path.split("/")
            if "o" in parts:
                idx = parts.index("o")
                if idx + 1 < len(parts):
                    encoded_obj = "/".join(parts[idx + 1 :])
                    return urllib.parse.unquote(encoded_obj)
        except Exception:
            return ""
        return ""
    return value.replace("\\", "/")


def _public_url(bucket: str, object_path: str) -> str:
    encoded = urllib.parse.quote(object_path, safe="")
    return f"https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded}?alt=media"


def _http_status(url: str, timeout_sec: int) -> tuple[int | None, str | None]:
    req = urllib.request.Request(url, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
            return int(resp.status), None
    except Exception as exc:  # noqa: BLE001
        msg = str(exc)
        # Try to parse "HTTP Error 404: Not Found"
        if "HTTP Error" in msg:
            try:
                code = int(msg.split("HTTP Error", 1)[1].split(":", 1)[0].strip())
                return code, msg
            except Exception:
                pass
        return None, msg


def _check_one(
    *,
    bucket_obj: storage.bucket,
    bucket_name: str,
    field: str,
    raw: str,
    timeout_sec: int,
) -> UrlCheck:
    object_path = _object_path_from_raw(raw, bucket_name)
    if not raw.strip():
        return UrlCheck(
            field=field,
            raw=raw,
            object_path="",
            admin_exists=None,
            public_url="",
            http_status=None,
            http_ok=True,
            error=None,
        )
    if not object_path:
        return UrlCheck(
            field=field,
            raw=raw,
            object_path="",
            admin_exists=None,
            public_url="",
            http_status=None,
            http_ok=False,
            error="cannot derive object path (bucket mismatch or malformed url/path)",
        )

    exists = bucket_obj.blob(object_path).exists()
    url = _public_url(bucket_name, object_path)
    status, err = _http_status(url, timeout_sec=timeout_sec)
    http_ok = status is not None and 200 <= status < 300
    return UrlCheck(
        field=field,
        raw=raw,
        object_path=object_path,
        admin_exists=exists,
        public_url=url,
        http_status=status,
        http_ok=http_ok,
        error=err,
    )


def run(args: argparse.Namespace) -> int:
    cred = credentials.Certificate(args.service_account)
    firebase_admin.initialize_app(cred, {"storageBucket": args.bucket})
    db = firestore.client(database_id=args.database_id)
    bucket_obj = storage.bucket()

    snap = db.collection(args.collection).get()
    docs = list(snap)
    print(f"[INFO] docs in {args.collection}: {len(docs)}")

    report: dict[str, Any] = {
        "bucket": args.bucket,
        "database_id": args.database_id,
        "collection": args.collection,
        "docs": [],
    }

    total_checks = 0
    total_fail = 0
    for doc in docs:
        data = doc.to_dict() or {}
        entry: dict[str, Any] = {"id": doc.id, "checks": []}
        for field in ("imagePath", "thumbPath", "thumbnailPath", "cardPath"):
            raw = str(data.get(field, "") or "")
            check = _check_one(
                bucket_obj=bucket_obj,
                bucket_name=args.bucket,
                field=field,
                raw=raw,
                timeout_sec=args.timeout_sec,
            )
            entry["checks"].append(asdict(check))
            if raw.strip():
                total_checks += 1
                if not check.http_ok or check.admin_exists is False:
                    total_fail += 1
                    print(
                        f"[FAIL] {doc.id}.{field} exists={check.admin_exists} "
                        f"http={check.http_status} path={check.object_path}"
                    )
        report["docs"].append(entry)

    print(f"[INFO] checks: {total_checks}")
    print(f"[INFO] fails : {total_fail}")

    out_path = Path(args.out_json)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] report: {out_path}")
    return 1 if total_fail > 0 else 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--service-account", required=True)
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--database-id", default="(default)")
    parser.add_argument("--collection", default="skins_catalog")
    parser.add_argument("--out-json", default="verify_output/skin_urls_report.json")
    parser.add_argument("--timeout-sec", type=int, default=15)
    code = run(parser.parse_args())
    raise SystemExit(code)


if __name__ == "__main__":
    main()

