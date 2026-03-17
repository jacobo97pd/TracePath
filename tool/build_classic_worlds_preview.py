from __future__ import annotations

import json
import math
import random
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any, Dict, List, Sequence


ROOT = Path(__file__).resolve().parents[1]
CLASSIC_PACK_PATH = ROOT / "assets" / "levels" / "pack_all_v1.json"
OUT_DIR = ROOT / "exports" / "classic_worlds"
GROUPED_PATH = OUT_DIR / "classic_grouped_by_difficulty_v1.json"
RANDOMIZED_PATH = OUT_DIR / "classic_randomized_v1.json"
WORLDS_PATH = OUT_DIR / "classic_worlds_preview_v1.json"
SUMMARY_PATH = OUT_DIR / "classic_worlds_summary.md"
SHUFFLE_SEED = 20260316
WORLD_SIZE = 24


def _bucket_for_difficulty(tag: str) -> str:
    if tag in {"d1", "d2"}:
        return "easy"
    if tag in {"d3", "d4"}:
        return "medium"
    if tag in {"d5"}:
        return "hard"
    return "unknown"


def _world_mix_profile(world_index: int) -> Dict[str, int]:
    # Keep early worlds lighter, then progressively add medium/hard levels.
    if world_index <= 2:
        return {"easy": 18, "medium": 5, "hard": 1}
    if world_index <= 5:
        return {"easy": 14, "medium": 8, "hard": 2}
    if world_index <= 8:
        return {"easy": 11, "medium": 10, "hard": 3}
    return {"easy": 8, "medium": 11, "hard": 5}


def _load_levels() -> List[Dict[str, Any]]:
    payload = json.loads(CLASSIC_PACK_PATH.read_text(encoding="utf-8"))
    levels = payload.get("levels", [])
    if not isinstance(levels, list):
        raise ValueError("Classic pack has no levels array")
    return [dict(level) for level in levels if isinstance(level, dict)]


def _shuffle_buckets(levels: Sequence[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    rng = random.Random(SHUFFLE_SEED)
    grouped: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    for level in levels:
        bucket = _bucket_for_difficulty(str(level.get("difficultyTag", "unknown")))
        grouped[bucket].append(level)
    for bucket_levels in grouped.values():
        rng.shuffle(bucket_levels)
    return grouped


def _build_randomized_order(grouped: Dict[str, List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    pools = {key: list(value) for key, value in grouped.items()}
    randomized: List[Dict[str, Any]] = []
    world_index = 1
    while any(pools.get(name) for name in ("easy", "medium", "hard")):
        profile = _world_mix_profile(world_index)
        world_chunk: List[Dict[str, Any]] = []
        for bucket in ("easy", "medium", "hard"):
            take = min(profile[bucket], len(pools.get(bucket, [])))
            if take > 0:
                world_chunk.extend(pools[bucket][:take])
                pools[bucket] = pools[bucket][take:]
        if len(world_chunk) < WORLD_SIZE:
            leftovers: List[Dict[str, Any]] = []
            for bucket in ("easy", "medium", "hard"):
                leftovers.extend(pools.get(bucket, [])[: WORLD_SIZE - len(world_chunk)])
                pools[bucket] = pools.get(bucket, [])[max(0, WORLD_SIZE - len(world_chunk)) :]
                if len(world_chunk) + len(leftovers) >= WORLD_SIZE:
                    break
            world_chunk.extend(leftovers[: WORLD_SIZE - len(world_chunk)])
        randomized.extend(world_chunk)
        world_index += 1
    return randomized


def _build_worlds(randomized: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    worlds: List[Dict[str, Any]] = []
    total_worlds = math.ceil(len(randomized) / WORLD_SIZE)
    for i in range(total_worlds):
        chunk = list(randomized[i * WORLD_SIZE : (i + 1) * WORLD_SIZE])
        difficulty_counter = Counter(
            _bucket_for_difficulty(str(level.get("difficultyTag", "unknown")))
            for level in chunk
        )
        size_counter = Counter()
        for level in chunk:
            size = level.get("size")
            if isinstance(size, dict):
                size_key = f'{size.get("w")}x{size.get("h")}'
            else:
                size_key = f"{size}x{size}"
            size_counter[size_key] += 1
        worlds.append(
            {
                "world": i + 1,
                "level_count": len(chunk),
                "difficulty_mix": dict(sorted(difficulty_counter.items())),
                "size_mix": dict(sorted(size_counter.items())),
                "level_ids": [str(level.get("id", "")) for level in chunk],
            }
        )
    return worlds


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    levels = _load_levels()
    grouped = _shuffle_buckets(levels)
    randomized = _build_randomized_order(grouped)
    worlds = _build_worlds(randomized)

    grouped_payload = {
        "source_pack": "pack_all_v1.json",
        "shuffle_seed": SHUFFLE_SEED,
        "counts": {key: len(value) for key, value in sorted(grouped.items())},
        "buckets": {
            key: [str(level.get("id", "")) for level in value]
            for key, value in sorted(grouped.items())
        },
    }
    randomized_payload = {
        "source_pack": "pack_all_v1.json",
        "shuffle_seed": SHUFFLE_SEED,
        "count": len(randomized),
        "level_ids": [str(level.get("id", "")) for level in randomized],
    }
    worlds_payload = {
        "source_pack": "pack_all_v1.json",
        "shuffle_seed": SHUFFLE_SEED,
        "world_size": WORLD_SIZE,
        "world_count": len(worlds),
        "worlds": worlds,
    }

    GROUPED_PATH.write_text(
        json.dumps(grouped_payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    RANDOMIZED_PATH.write_text(
        json.dumps(randomized_payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    WORLDS_PATH.write_text(
        json.dumps(worlds_payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    counter = Counter(_bucket_for_difficulty(str(level.get("difficultyTag", "unknown"))) for level in levels)
    summary_lines = [
        "# Classic Worlds Preview",
        "",
        f"- Source pack: `pack_all_v1.json`",
        f"- Total levels: {len(levels)}",
        f"- Shuffle seed: {SHUFFLE_SEED}",
        f"- Suggested world size: {WORLD_SIZE}",
        f"- Suggested worlds: {len(worlds)}",
        "",
        "## Difficulty Buckets",
        "",
    ]
    summary_lines.extend(f"- {key}: {value}" for key, value in sorted(counter.items()))
    summary_lines.extend(["", "## Worlds Preview", ""])
    for world in worlds:
        summary_lines.append(
            f"- World {world['world']}: {world['level_count']} levels | "
            f"difficulty={world['difficulty_mix']} | sizes={world['size_mix']}"
        )
    SUMMARY_PATH.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print(f"[OK] classic levels: {len(levels)}")
    print(f"[OK] grouped: {GROUPED_PATH}")
    print(f"[OK] randomized order: {RANDOMIZED_PATH}")
    print(f"[OK] worlds preview: {WORLDS_PATH}")
    print(f"[OK] summary: {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
