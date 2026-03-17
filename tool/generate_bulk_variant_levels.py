from __future__ import annotations

import argparse
import csv
import json
import random
from pathlib import Path
from typing import Any, Dict, List, Sequence

import generate_variant_test_levels as base

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE_PACK = ROOT / "assets" / "levels" / "pack_all_v1.json"
DEFAULT_OUT_DIR = ROOT / "exports" / "bulk_variant_levels"

DIFF_TO_TAGS = {
    "easy": ("d1", "d2"),
    "medium": ("d3", "d4"),
    "hard": ("d5",),
}


def _parse_variants(raw: str) -> List[str]:
    if raw.strip().lower() == "all":
        return list(base.VARIANTS)
    requested = [v.strip() for v in raw.split(",") if v.strip()]
    invalid = [v for v in requested if v not in base.VARIANTS]
    if invalid:
        raise ValueError(
            f"Invalid variant(s): {', '.join(invalid)}. "
            f"Valid: {', '.join(base.VARIANTS)}"
        )
    if not requested:
        raise ValueError("No variants requested.")
    return requested


def _build_pool(levels: Sequence[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    by_tag: Dict[str, List[Dict[str, Any]]] = {}
    for lv in levels:
        tag = str(lv.get("difficultyTag", ""))
        by_tag.setdefault(tag, []).append(lv)
    for tag, items in by_tag.items():
        items.sort(key=lambda x: str(x.get("id", "")))
    return by_tag


def _pick_source_level(
    *,
    levels: Sequence[Dict[str, Any]],
    by_tag: Dict[str, List[Dict[str, Any]]],
    difficulty: str,
    rng: random.Random,
) -> Dict[str, Any]:
    tags = DIFF_TO_TAGS[difficulty]
    pool: List[Dict[str, Any]] = []
    for tag in tags:
        pool.extend(by_tag.get(tag, []))
    def _has_solution(level: Dict[str, Any]) -> bool:
        solution = level.get("solution")
        if not isinstance(solution, list) or not solution:
            return False
        size = level.get("size", {})
        if isinstance(size, dict):
            w = int(size.get("w", 0))
            h = int(size.get("h", 0))
        else:
            w = int(size or 0)
            h = w
        expected = w * h
        return expected > 0 and len(solution) == expected

    solved_pool = [lv for lv in pool if _has_solution(lv)]
    if solved_pool:
        pool = solved_pool

    if not pool:
        pool = list(levels)
    if not pool:
        raise RuntimeError("Source pack has no levels.")
    return rng.choice(pool)


def _write_summary(levels: Sequence[Dict[str, Any]], out_csv: Path, out_md: Path) -> None:
    fields = [
        "id",
        "variant",
        "difficulty_estimate",
        "grid_size",
        "path_length",
        "num_clues",
        "clue_density",
        "sequence_length",
        "sequence_start",
        "sequence_step",
        "representation",
        "turns",
        "max_straight",
        "avg_straight",
        "corners",
        "borders",
        "inners",
        "num_walls",
        "alphabet_start_char",
        "multiple_base",
        "roman_max_value",
        "dice_mode",
        "arithmetic_mode",
        "source_level_id",
    ]

    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for lv in levels:
            m = dict(lv.get("metrics", {}))
            row = {"id": lv.get("id", "")}
            row.update({k: m.get(k, "") for k in fields if k != "id"})
            row["source_level_id"] = lv.get("meta", {}).get("source_level_id", "")
            writer.writerow(row)

    lines: List[str] = []
    lines.append("| " + " | ".join(fields) + " |")
    lines.append("|" + "|".join(["---"] * len(fields)) + "|")
    for lv in levels:
        m = lv.get("metrics", {})
        row = [str(lv.get("id", ""))]
        for field in fields[1:]:
            if field == "source_level_id":
                row.append(str(lv.get("meta", {}).get("source_level_id", "")))
            else:
                row.append(str(m.get(field, "")))
        lines.append("| " + " | ".join(row) + " |")
    out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate bulk variant packs (100/200+ levels per variant)."
    )
    parser.add_argument(
        "--per-variant",
        type=int,
        default=100,
        help="How many levels to generate for each variant (default: 100)",
    )
    parser.add_argument(
        "--variants",
        type=str,
        default="all",
        help=(
            "Comma-separated variants or 'all'. "
            "Valid: roman,alphabet,alphabet_reverse,multiples,multiples_roman,dice,arithmetic"
        ),
    )
    parser.add_argument(
        "--source-pack",
        type=Path,
        default=DEFAULT_SOURCE_PACK,
        help="Path to source pack with solved levels",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=DEFAULT_OUT_DIR,
        help="Output directory",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=20260314,
        help="Random seed for reproducible generation",
    )
    parser.add_argument(
        "--prefix",
        type=str,
        default="bulk",
        help="ID prefix for generated levels",
    )
    args = parser.parse_args()

    if args.per_variant <= 0:
        raise ValueError("--per-variant must be > 0")

    variants = _parse_variants(args.variants)

    source_data = json.loads(args.source_pack.read_text(encoding="utf-8"))
    source_levels = source_data.get("levels", [])
    if not isinstance(source_levels, list) or not source_levels:
        raise RuntimeError("Source pack has no levels.")

    by_tag = _build_pool(source_levels)

    out_dir = args.out_dir
    out_levels_dir = out_dir / "levels"
    out_levels_dir.mkdir(parents=True, exist_ok=True)

    pack_name = f"{args.prefix}_variant_pack_{args.per_variant}_each"
    out_pack = out_dir / f"{pack_name}.json"
    out_csv = out_dir / f"{pack_name}_metrics.csv"
    out_md = out_dir / f"{pack_name}_metrics.md"

    difficulty_cycle = [plan.estimate for plan in base.DIFF_PLANS]

    generated: List[Dict[str, Any]] = []
    for variant_index, variant in enumerate(variants):
        rng = random.Random(args.seed + variant_index * 100_003)
        for i in range(args.per_variant):
            difficulty = difficulty_cycle[i % len(difficulty_cycle)]
            src = _pick_source_level(
                levels=source_levels,
                by_tag=by_tag,
                difficulty=difficulty,
                rng=rng,
            )
            entry = {
                "variant": variant,
                "difficulty_estimate": difficulty,
                "source": src,
            }
            payload = base.build_level_payload(entry, i)
            payload["id"] = f"{args.prefix}_{variant}_{i + 1:03d}"
            payload.setdefault("meta", {})
            payload["meta"]["generation_batch"] = pack_name
            payload["meta"]["generation_index"] = i + 1

            generated.append(payload)
            (out_levels_dir / f"{payload['id']}.json").write_text(
                json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )

    pack = {
        "packId": f"{args.prefix}_variants",
        "version": pack_name,
        "count": len(generated),
        "levels": generated,
    }
    out_pack.write_text(
        json.dumps(pack, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    _write_summary(generated, out_csv, out_md)

    print(f"[OK] variants: {', '.join(variants)}")
    print(f"[OK] generated: {len(generated)} levels ({args.per_variant} per variant)")
    print(f"[OK] pack: {out_pack}")
    print(f"[OK] per-level files: {out_levels_dir}")
    print(f"[OK] metrics csv: {out_csv}")
    print(f"[OK] metrics md: {out_md}")


if __name__ == "__main__":
    main()
