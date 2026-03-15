from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import List

from tool.verify_levels_core import (
    LevelDef,
    autodiscover_manifest,
    load_manifest_map,
    normalize_levels,
    parse_levels_file,
    resolve_image_for_level,
    verify_level,
)


def _numeric_id_suffix(level: LevelDef) -> int:
    suffix = ""
    for ch in reversed(level.id):
        if ch.isdigit():
            suffix = ch + suffix
        elif suffix:
            break
    return int(suffix) if suffix else -1


def _select_levels(levels: List[LevelDef], start_level: int) -> List[LevelDef]:
    by_id = [lv for lv in levels if _numeric_id_suffix(lv) >= start_level]
    if by_id:
        return by_id
    return levels[max(0, start_level - 1) :]


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Deterministic verifier for Zip Path levels: compares clues/walls to screenshot "
            "and validates solvability with a complete backtracking solver."
        )
    )
    parser.add_argument("--levels-json", required=True, type=Path)
    parser.add_argument("--images-dir", required=True, type=Path)
    parser.add_argument("--start-level", type=int, default=14)
    parser.add_argument("--outdir", required=True, type=Path)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=None,
        help="Optional image manifest json. If omitted, autodiscovery is attempted.",
    )
    parser.add_argument(
        "--max-attempts-per-level",
        type=int,
        default=200,
        help="Attempts block before switching solver strategy (repair loop never advances unsolved level).",
    )
    args = parser.parse_args()

    if not args.levels_json.exists():
        print(f"[FAIL] levels json not found: {args.levels_json}")
        return 2
    if not args.images_dir.exists():
        print(f"[FAIL] images dir not found: {args.images_dir}")
        return 2

    args.outdir.mkdir(parents=True, exist_ok=True)

    manifest_path = args.manifest
    if manifest_path is None:
        manifest_path = autodiscover_manifest(args.levels_json)
    manifest_map = load_manifest_map(manifest_path)
    if manifest_path:
        print(f"[INFO] using manifest: {manifest_path}")

    records = parse_levels_file(args.levels_json)
    levels = normalize_levels(records)
    targets = _select_levels(levels, args.start_level)
    if not targets:
        print(f"[INFO] no levels to process from start-level={args.start_level}")
        return 0

    print(
        f"[INFO] processing {len(targets)} levels from start-level={args.start_level} "
        f"(total levels={len(levels)})"
    )

    reports = []
    for i, level in enumerate(targets, start=1):
        image_path = resolve_image_for_level(level, args.images_dir, manifest_map)
        if image_path is None:
            print(f"[FAIL] {level.id}: could not resolve screenshot in {args.images_dir}")
            fail_report = {
                "level_id": level.id,
                "grid_size": {"w": level.width, "h": level.height},
                "failure_reason": "missing image",
                "passed": False,
            }
            reports.append(fail_report)
            (args.outdir / "report.json").write_text(
                json.dumps({"reports": reports}, indent=2), encoding="utf-8"
            )
            return 1

        level_out = args.outdir / level.id
        result = verify_level(
            level,
            image_path,
            level_out,
            max_attempts_per_level=max(1, int(args.max_attempts_per_level)),
        )
        reports.append(result.to_json())
        (level_out / "report.json").write_text(
            json.dumps(result.to_json(), indent=2), encoding="utf-8"
        )
        (args.outdir / "report.json").write_text(
            json.dumps({"reports": reports}, indent=2), encoding="utf-8"
        )

        summary = (
            f"[{i}/{len(targets)}] {result.level_id} "
            f"clues={'OK' if result.clues_ok else 'FAIL'} "
            f"walls={'OK' if result.walls_ok else 'FAIL'} "
            f"solver={result.solver_status} "
            f"attempts={result.attempts_count} "
            f"time={result.duration_ms}ms"
        )
        print(summary)

        if not result.passed:
            print(f"[FAIL] stopped at {result.level_id}: {result.failure_reason}")
            print(f"[FAIL] debug artifacts: {level_out}")
            return 1

    print("[PASS] all processed levels passed.")
    print(f"[PASS] consolidated report: {args.outdir / 'report.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
