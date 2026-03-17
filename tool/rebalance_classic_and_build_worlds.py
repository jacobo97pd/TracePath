from __future__ import annotations

import json
import math
import random
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple


ROOT = Path(__file__).resolve().parents[1]
CLASSIC_PACK_PATH = ROOT / "assets" / "levels" / "pack_all_v1.json"
MASTER_PACK_PATH = ROOT / "assets" / "levels" / "master_pack_v1.json"
VARIANT_PACK_PATHS = [
    ROOT / "assets" / "levels" / "pack_variant_alphabet_v1.json",
    ROOT / "assets" / "levels" / "pack_variant_alphabet_reverse_v1.json",
    ROOT / "assets" / "levels" / "pack_variant_multiples_v1.json",
    ROOT / "assets" / "levels" / "pack_variant_roman_v1.json",
    ROOT / "assets" / "levels" / "pack_variant_multiples_roman_v1.json",
]
OUT_DIR = ROOT / "exports" / "classic_worlds"
REBALANCED_AUDIT_PATH = OUT_DIR / "classic_difficulty_rebalanced_v1.json"
WORLDS_PACK_PATH = OUT_DIR / "classic_worlds_pack_v1.json"
WORLD_SUMMARY_PATH = OUT_DIR / "classic_worlds_balanced_summary.md"
SHUFFLE_SEED = 20260316
WORLD_SIZE = 24


def _size_of(level: Dict[str, Any]) -> Tuple[int, int]:
    size = level.get("size")
    if isinstance(size, dict):
        return int(size["w"]), int(size["h"])
    n = int(size)
    return n, n


def _possible_edges(width: int, height: int) -> int:
    return ((width - 1) * height) + ((height - 1) * width)


def _difficulty_score(level: Dict[str, Any]) -> float:
    width, height = _size_of(level)
    cells = width * height
    size_score = {
        25: 0.4,
        36: 1.0,
        49: 1.9,
        64: 2.8,
    }.get(cells, 1.0 + max(0, cells - 36) / 16.0)

    clues = len(level.get("clues", []))
    clue_density = clues / max(1, cells)
    inverse_clue_score = max(0.0, 0.34 - clue_density) * 18.0

    walls = len(level.get("walls", []))
    wall_density = walls / max(1, _possible_edges(width, height))
    wall_score = wall_density * 20.0

    source_origin = str(level.get("source_origin") or level.get("source") or "").lower()
    source_bonus = 0.0
    if "linkedin_js" in source_origin:
        source_bonus = 0.6
    elif "linkedin_editor" in source_origin:
        source_bonus = 0.2

    return round(size_score + inverse_clue_score + wall_score + source_bonus, 4)


def _assign_rebalanced_tags(levels: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    ranked = []
    for index, level in enumerate(levels):
        score = _difficulty_score(level)
        ranked.append((score, index, level))
    ranked.sort(key=lambda item: (item[0], item[1]))

    total = len(ranked)
    cut_d1 = max(1, round(total * 0.08))
    cut_d2 = max(cut_d1 + 1, round(total * 0.45))
    cut_d3 = max(cut_d2 + 1, round(total * 0.73))
    cut_d4 = max(cut_d3 + 1, round(total * 0.88))

    output: List[Dict[str, Any]] = []
    for position, (score, _, level) in enumerate(ranked):
        cloned = json.loads(json.dumps(level))
        old_tag = str(cloned.get("difficultyTag", "unknown"))
        if position < cut_d1:
            new_tag = "d1"
        elif position < cut_d2:
            new_tag = "d2"
        elif position < cut_d3:
            new_tag = "d3"
        elif position < cut_d4:
            new_tag = "d4"
        else:
            new_tag = "d5"
        cloned["difficultyTag"] = new_tag
        meta = cloned.get("meta")
        if not isinstance(meta, dict):
            meta = {}
            cloned["meta"] = meta
        meta["difficulty_rebalanced_from"] = old_tag
        meta["difficulty_score"] = score
        output.append(cloned)
    return output


def _bucket(tag: str) -> str:
    if tag in {"d1", "d2"}:
        return "easy"
    if tag in {"d3", "d4"}:
        return "medium"
    return "hard"


def _world_bucket(level: Dict[str, Any]) -> str:
    variant = str((level.get("meta") or {}).get("variant") or level.get("variant") or "classic").strip().lower()
    if variant in {"alphabet", "alphabet_reverse", "multiples", "roman", "multiples_roman"}:
        return "extra_hard"
    return _bucket(str(level.get("difficultyTag", "d5")))


def _mix_for_world(world_index: int) -> Dict[str, int]:
    if world_index <= 2:
        return {"easy": 16, "medium": 6, "hard": 2, "extra_hard": 0}
    if world_index <= 5:
        return {"easy": 12, "medium": 8, "hard": 4, "extra_hard": 0}
    if world_index <= 8:
        return {"easy": 9, "medium": 8, "hard": 5, "extra_hard": 2}
    if world_index <= 11:
        return {"easy": 6, "medium": 7, "hard": 6, "extra_hard": 5}
    return {"easy": 4, "medium": 6, "hard": 6, "extra_hard": 8}


def _load_variant_levels() -> List[Dict[str, Any]]:
    levels: List[Dict[str, Any]] = []
    for path in VARIANT_PACK_PATHS:
        payload = json.loads(path.read_text(encoding="utf-8"))
        for level in payload.get("levels", []):
            if not isinstance(level, dict):
                continue
            cloned = json.loads(json.dumps(level))
            cloned["difficultyTag"] = "d5"
            cloned["source_pack"] = path.stem
            meta = cloned.get("meta")
            if not isinstance(meta, dict):
                meta = {}
                cloned["meta"] = meta
            meta["challenge_tier"] = "extra_hard"
            meta["source_pack"] = path.stem
            meta["variant"] = str(meta.get("variant") or "classic")
            levels.append(cloned)
    return levels


def _build_worlds(levels: Sequence[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    rng = random.Random(SHUFFLE_SEED)
    pools: Dict[str, List[Dict[str, Any]]] = {
        "easy": [],
        "medium": [],
        "hard": [],
        "extra_hard": [],
    }
    for level in levels:
        pools[_world_bucket(level)].append(level)
    for pool in pools.values():
        rng.shuffle(pool)

    randomized_order: List[Dict[str, Any]] = []
    worlds: List[Dict[str, Any]] = []
    world_index = 1
    while any(pools.values()):
        profile = _mix_for_world(world_index)
        chunk: List[Dict[str, Any]] = []
        for bucket_name in ("easy", "medium", "hard", "extra_hard"):
            take = min(profile[bucket_name], len(pools[bucket_name]))
            if take > 0:
                chunk.extend(pools[bucket_name][:take])
                pools[bucket_name] = pools[bucket_name][take:]
        if len(chunk) < WORLD_SIZE:
            for bucket_name in ("extra_hard", "hard", "medium", "easy"):
                need = WORLD_SIZE - len(chunk)
                if need <= 0:
                    break
                take = min(need, len(pools[bucket_name]))
                if take > 0:
                    chunk.extend(pools[bucket_name][:take])
                    pools[bucket_name] = pools[bucket_name][take:]
        randomized_order.extend(chunk)
        size_mix = Counter()
        difficulty_mix = Counter()
        for level in chunk:
            width, height = _size_of(level)
            size_mix[f"{width}x{height}"] += 1
            difficulty_mix[_world_bucket(level)] += 1
        variants_mix = Counter(
            str((level.get("meta") or {}).get("variant") or level.get("variant") or "classic")
            for level in chunk
        )
        worlds.append(
            {
                "world": world_index,
                "level_count": len(chunk),
                "difficulty_mix": dict(sorted(difficulty_mix.items())),
                "size_mix": dict(sorted(size_mix.items())),
                "variant_mix": dict(sorted(variants_mix.items())),
                "level_ids": [str(level.get("id", "")) for level in chunk],
            }
        )
        world_index += 1
    return randomized_order, worlds


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    classic = json.loads(CLASSIC_PACK_PATH.read_text(encoding="utf-8"))
    levels = classic.get("levels", [])
    if not isinstance(levels, list):
        raise ValueError("Classic pack has no levels array")

    rebalanced = _assign_rebalanced_tags([dict(level) for level in levels if isinstance(level, dict)])
    classic["levels"] = rebalanced
    classic["count"] = len(rebalanced)
    classic["version"] = "pack_all_v1_classic_rebalanced"
    CLASSIC_PACK_PATH.write_text(json.dumps(classic, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    if MASTER_PACK_PATH.exists():
        master = json.loads(MASTER_PACK_PATH.read_text(encoding="utf-8"))
        master["levels"] = rebalanced
        master["count"] = len(rebalanced)
        master["version"] = "master_pack_v1_classic_rebalanced"
        MASTER_PACK_PATH.write_text(json.dumps(master, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    variant_levels = _load_variant_levels()
    world_pool = rebalanced + variant_levels
    randomized_order, worlds = _build_worlds(world_pool)

    audit = {
        "source_pack": "pack_all_v1.json",
        "shuffle_seed": SHUFFLE_SEED,
        "count": len(rebalanced),
        "variant_extra_hard_count": len(variant_levels),
        "difficulty_distribution": dict(sorted(Counter(str(level.get("difficultyTag", "unknown")) for level in rebalanced).items())),
        "levels": [
            {
                "id": level["id"],
                "difficultyTag": level.get("difficultyTag"),
                "difficulty_score": (level.get("meta") or {}).get("difficulty_score"),
                "difficulty_rebalanced_from": (level.get("meta") or {}).get("difficulty_rebalanced_from"),
            }
            for level in rebalanced
        ],
    }
    REBALANCED_AUDIT_PATH.write_text(json.dumps(audit, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    worlds_pack = {
        "packId": "classic_worlds_preview",
        "version": "classic_worlds_pack_v1",
        "shuffle_seed": SHUFFLE_SEED,
        "world_size": WORLD_SIZE,
        "world_count": len(worlds),
        "classic_level_count": len(rebalanced),
        "variant_extra_hard_count": len(variant_levels),
        "randomized_level_ids": [str(level.get("id", "")) for level in randomized_order],
        "worlds": worlds,
    }
    WORLDS_PACK_PATH.write_text(json.dumps(worlds_pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    summary_lines = [
        "# Classic Difficulty Rebalance",
        "",
        f"- Total levels: {len(rebalanced)}",
        f"- Variant extra-hard levels: {len(variant_levels)}",
        f"- Shuffle seed: {SHUFFLE_SEED}",
        f"- World size: {WORLD_SIZE}",
        f"- World count: {len(worlds)}",
        "",
        "## Difficulty Distribution",
        "",
    ]
    distribution = Counter(str(level.get("difficultyTag", "unknown")) for level in rebalanced)
    summary_lines.extend(f"- {key}: {value}" for key, value in sorted(distribution.items()))
    summary_lines.extend(["", "## Worlds", ""])
    for world in worlds:
        summary_lines.append(
            f"- World {world['world']}: {world['level_count']} levels | "
            f"difficulty={world['difficulty_mix']} | variants={world['variant_mix']} | sizes={world['size_mix']}"
        )
    WORLD_SUMMARY_PATH.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print(f"[OK] rebalanced classic levels: {len(rebalanced)}")
    print(f"[OK] audit: {REBALANCED_AUDIT_PATH}")
    print(f"[OK] worlds pack: {WORLDS_PACK_PATH}")
    print(f"[OK] summary: {WORLD_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
