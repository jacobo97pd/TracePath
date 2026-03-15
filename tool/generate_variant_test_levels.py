from __future__ import annotations

import csv
import json
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Tuple


ROOT = Path(__file__).resolve().parents[1]
PACK_PATH = ROOT / "assets" / "levels" / "pack_all_v1.json"
OUT_DIR = ROOT / "exports" / "variant_tests"
OUT_LEVELS_DIR = OUT_DIR / "levels"
OUT_PACK_PATH = OUT_DIR / "variant_test_pack_v1.json"
OUT_SUMMARY_CSV = OUT_DIR / "variant_test_metrics.csv"
OUT_SUMMARY_MD = OUT_DIR / "variant_test_metrics.md"


@dataclass(frozen=True)
class DifficultyPlan:
    estimate: str
    source_tags: Tuple[str, ...]


DIFF_PLANS: List[DifficultyPlan] = [
    DifficultyPlan("easy", ("d1", "d2")),
    DifficultyPlan("easy", ("d1", "d2")),
    DifficultyPlan("medium", ("d3", "d4")),
    DifficultyPlan("medium", ("d3", "d4")),
    DifficultyPlan("hard", ("d5",)),
]

VARIANTS = (
    "roman",
    "alphabet",
    "multiples",
    "multiples_roman",
    "dice",
    "arithmetic",
)

ALPHABET_STARTS = ("A", "J", "M", "Q", "C")
MULTIPLE_BASES = (2, 3, 4, 5, 3)
DICE_MODES = ("face", "face", "sum", "sum", "face")
ARITH_MODES = ("sum", "sum", "mixed", "mixed", "mixed")


def romanize(value: int) -> str:
    if value <= 0:
        return str(value)
    numerals = (
        (1000, "M"),
        (900, "CM"),
        (500, "D"),
        (400, "CD"),
        (100, "C"),
        (90, "XC"),
        (50, "L"),
        (40, "XL"),
        (10, "X"),
        (9, "IX"),
        (5, "V"),
        (4, "IV"),
        (1, "I"),
    )
    out = []
    n = value
    for dec, sym in numerals:
        while n >= dec:
            out.append(sym)
            n -= dec
    return "".join(out)


def idx_to_xy(idx: int, w: int) -> Tuple[int, int]:
    return idx % w, idx // w


def wall_edges_to_hv_segments(
    walls: List[Dict[str, int]],
    width: int,
    height: int,
) -> Dict[str, List[Dict[str, int]]]:
    h = [[False] * width for _ in range(height + 1)]
    v = [[False] * (width + 1) for _ in range(height)]

    for wall in walls:
        a = int(wall["cell1"])
        b = int(wall["cell2"])
        ax, ay = idx_to_xy(a, width)
        bx, by = idx_to_xy(b, width)

        if ax == bx and abs(ay - by) == 1:
            y = max(ay, by)
            x = ax
            h[y][x] = True
        elif ay == by and abs(ax - bx) == 1:
            x = max(ax, bx)
            y = ay
            v[y][x] = True

    h_segments: List[Dict[str, int]] = []
    for y in range(height + 1):
        x = 0
        while x < width:
            if not h[y][x]:
                x += 1
                continue
            start = x
            while x < width and h[y][x]:
                x += 1
            h_segments.append({"x": start, "y": y, "len": x - start})

    v_segments: List[Dict[str, int]] = []
    for x in range(width + 1):
        y = 0
        while y < height:
            if not v[y][x]:
                y += 1
                continue
            start = y
            while y < height and v[y][x]:
                y += 1
            v_segments.append({"x": x, "y": start, "len": y - start})

    return {"h": h_segments, "v": v_segments}


def path_turn_metrics(solution: List[int], width: int) -> Tuple[int, int, float]:
    if len(solution) < 2:
        return 0, len(solution), float(len(solution))
    dirs: List[Tuple[int, int]] = []
    for i in range(len(solution) - 1):
        x1, y1 = idx_to_xy(solution[i], width)
        x2, y2 = idx_to_xy(solution[i + 1], width)
        dirs.append((x2 - x1, y2 - y1))

    turns = 0
    streaks: List[int] = []
    run = 1
    for i in range(1, len(dirs)):
        if dirs[i] == dirs[i - 1]:
            run += 1
        else:
            turns += 1
            streaks.append(run)
            run = 1
    streaks.append(run)
    max_straight = max(streaks) if streaks else 1
    avg_straight = sum(streaks) / len(streaks) if streaks else 1.0
    return turns, max_straight, avg_straight


def clue_position_metrics(
    clues: List[Dict[str, int]],
    width: int,
    height: int,
) -> Tuple[int, int, int]:
    corners = 0
    borders = 0
    inners = 0
    for c in clues:
        x = int(c["x"])
        y = int(c["y"])
        is_corner = (x in (0, width - 1)) and (y in (0, height - 1))
        is_border = (x in (0, width - 1)) or (y in (0, height - 1))
        if is_corner:
            corners += 1
        elif is_border:
            borders += 1
        else:
            inners += 1
    return corners, borders, inners


def build_display_labels(
    variant: str,
    clue_numbers: List[int],
    variant_index: int,
) -> Tuple[Dict[str, str], Dict[str, Any]]:
    labels: Dict[str, str] = {}
    extra_meta: Dict[str, Any] = {}
    sorted_nums = sorted(clue_numbers)

    if variant == "roman":
        for n in sorted_nums:
            labels[str(n)] = romanize(n)
        extra_meta["sequence_rule"] = "I, II, III..."
        extra_meta["representation"] = "roman"
        extra_meta["roman_max_value"] = max(sorted_nums) if sorted_nums else 0

    elif variant == "alphabet":
        start_char = ALPHABET_STARTS[variant_index % len(ALPHABET_STARTS)]
        start_ord = ord(start_char)
        for n in sorted_nums:
            labels[str(n)] = chr(start_ord + (n - 1))
        extra_meta["sequence_rule"] = f"{start_char}, {chr(start_ord+1)}, {chr(start_ord+2)}..."
        extra_meta["representation"] = "alphabet"
        extra_meta["alphabet_start_char"] = start_char

    elif variant == "multiples":
        base = MULTIPLE_BASES[variant_index % len(MULTIPLE_BASES)]
        for n in sorted_nums:
            labels[str(n)] = str(base * n)
        extra_meta["sequence_rule"] = f"multiples of {base}"
        extra_meta["representation"] = "multiple"
        extra_meta["multiple_base"] = base

    elif variant == "multiples_roman":
        base = MULTIPLE_BASES[(variant_index + 1) % len(MULTIPLE_BASES)]
        for n in sorted_nums:
            labels[str(n)] = romanize(base * n)
        extra_meta["sequence_rule"] = f"roman multiples of {base}"
        extra_meta["representation"] = "multiple_roman"
        extra_meta["multiple_base"] = base
        extra_meta["roman_max_value"] = base * (max(sorted_nums) if sorted_nums else 0)

    elif variant == "dice":
        dice_mode = DICE_MODES[variant_index % len(DICE_MODES)]
        rng = random.Random(9000 + variant_index)
        for n in sorted_nums:
            if dice_mode == "face":
                face = ((n - 1) % 6) + 1
                labels[str(n)] = f"d{face}"
            else:
                target = ((n - 1) % 11) + 2
                a = rng.randint(1, min(6, target - 1))
                b = target - a
                if b < 1:
                    a, b = 1, target - 1
                if b > 6:
                    b = 6
                    a = max(1, target - b)
                labels[str(n)] = f"{a}+{b}"
        extra_meta["sequence_rule"] = "dice faces / dice sums"
        extra_meta["representation"] = "dice"
        extra_meta["dice_mode"] = dice_mode

    elif variant == "arithmetic":
        arithmetic_mode = ARITH_MODES[variant_index % len(ARITH_MODES)]
        rng = random.Random(12000 + variant_index)
        for n in sorted_nums:
            if arithmetic_mode == "sum":
                a = rng.randint(1, max(1, n))
                b = n - a
                if b < 0:
                    a, b = n, 0
                labels[str(n)] = f"{a}+{b}"
            elif arithmetic_mode == "mixed":
                if n > 2 and rng.random() < 0.5:
                    a = n + rng.randint(1, 4)
                    b = a - n
                    labels[str(n)] = f"{a}-{b}"
                else:
                    a = rng.randint(1, max(1, n))
                    b = n - a
                    labels[str(n)] = f"{a}+{b}"
            else:
                labels[str(n)] = str(n)
        extra_meta["sequence_rule"] = "simple arithmetic expressions"
        extra_meta["representation"] = "arithmetic"
        extra_meta["arithmetic_mode"] = arithmetic_mode

    return labels, extra_meta


def pick_levels(levels: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    by_tag: Dict[str, List[Dict[str, Any]]] = {}
    for lv in levels:
        by_tag.setdefault(str(lv.get("difficultyTag", "")), []).append(lv)

    # Keep deterministic and varied.
    for tag in by_tag:
        by_tag[tag].sort(key=lambda x: str(x.get("id", "")))

    rng = random.Random(20260311)
    used_ids: set[str] = set()
    chosen: List[Dict[str, Any]] = []

    for variant in VARIANTS:
        for plan in DIFF_PLANS:
            pool: List[Dict[str, Any]] = []
            for tag in plan.source_tags:
                pool.extend(by_tag.get(tag, []))
            pool = [lv for lv in pool if str(lv.get("id", "")) not in used_ids]
            if variant == "roman" and plan.estimate == "easy":
                square_5 = [
                    lv
                    for lv in pool
                    if int(lv["size"]["w"]) == 5 and int(lv["size"]["h"]) == 5
                ]
                if square_5:
                    pool = square_5
            if not pool:
                # fallback to any non-used level
                pool = [lv for lv in levels if str(lv.get("id", "")) not in used_ids]
            if not pool:
                raise RuntimeError("Not enough levels to build variant test pack.")
            lv = rng.choice(pool)
            used_ids.add(str(lv.get("id", "")))
            chosen.append(
                {
                    "variant": variant,
                    "difficulty_estimate": plan.estimate,
                    "source": lv,
                }
            )
    return chosen


def build_level_payload(entry: Dict[str, Any], variant_index: int) -> Dict[str, Any]:
    variant = entry["variant"]
    difficulty_estimate = entry["difficulty_estimate"]
    src = entry["source"]
    source_id = str(src["id"])
    width = int(src["size"]["w"])
    height = int(src["size"]["h"])
    size = width if width == height else {"w": width, "h": height}
    solution = [int(v) for v in src.get("solution", [])]
    clues = build_clues_from_solution(
        solution=solution,
        width=width,
        difficulty_estimate=difficulty_estimate,
        variant=variant,
        seed=4000 + variant_index * 17,
    )
    walls_hv = wall_edges_to_hv_segments(src.get("walls", []), width, height)
    clue_numbers = [int(c["n"]) for c in clues]
    labels, extra_meta = build_display_labels(variant, clue_numbers, variant_index)

    path_length = width * height
    num_clues = len(clues)
    clue_density = (num_clues / path_length) if path_length else 0.0
    sequence_length = max(clue_numbers) if clue_numbers else 0
    turns, max_straight, avg_straight = path_turn_metrics(solution, width)
    corners, borders, inners = clue_position_metrics(clues, width, height)

    representation = str(extra_meta.get("representation", variant))
    sequence_start = 1
    sequence_step = 1
    if "multiple_base" in extra_meta:
        sequence_start = int(extra_meta["multiple_base"])
        sequence_step = int(extra_meta["multiple_base"])

    level_id = f"test_{variant}_{variant_index + 1:03d}"

    metrics: Dict[str, Any] = {
        "variant": variant,
        "grid_size": width,
        "path_length": path_length,
        "num_clues": num_clues,
        "clue_density": round(clue_density, 4),
        "sequence_length": sequence_length,
        "sequence_start": sequence_start,
        "sequence_step": sequence_step,
        "representation": representation,
        "difficulty_estimate": difficulty_estimate,
        "turns": turns,
        "max_straight": max_straight,
        "avg_straight": round(avg_straight, 2),
        "corners": corners,
        "borders": borders,
        "inners": inners,
        "num_walls": len(src.get("walls", [])),
    }
    for optional_key in (
        "alphabet_start_char",
        "multiple_base",
        "roman_max_value",
        "dice_mode",
        "arithmetic_mode",
    ):
        if optional_key in extra_meta:
            metrics[optional_key] = extra_meta[optional_key]

    meta: Dict[str, Any] = {
        "variant": variant,
        "sequence_rule": str(extra_meta.get("sequence_rule", "numeric ascending")),
        "difficulty_target": difficulty_estimate,
        "representation": representation,
        "display_labels": labels,
        "source_level_id": source_id,
    }
    for key in (
        "alphabet_start_char",
        "multiple_base",
        "roman_max_value",
        "dice_mode",
        "arithmetic_mode",
    ):
        if key in extra_meta:
            meta[key] = extra_meta[key]

    return {
        "id": level_id,
        "size": size,
        "clues": clues,
        "walls": walls_hv,
        "meta": meta,
        "metrics": metrics,
    }


def build_clues_from_solution(
    solution: List[int],
    width: int,
    difficulty_estimate: str,
    variant: str,
    seed: int,
) -> List[Dict[str, int]]:
    if not solution:
        return []
    path_length = len(solution)
    rng = random.Random(seed)

    if difficulty_estimate == "easy":
        ratio = rng.uniform(0.30, 0.45)
    elif difficulty_estimate == "medium":
        ratio = rng.uniform(0.20, 0.32)
    else:
        ratio = rng.uniform(0.12, 0.22)

    target = max(4, min(path_length, round(path_length * ratio)))

    # Variant-specific readability constraints.
    if variant == "roman":
        if difficulty_estimate == "easy":
            target = min(target, 10)  # up to X
        elif difficulty_estimate == "medium":
            target = min(target, 20)  # up to XX
        target = max(5, target)
    elif variant in ("multiples_roman",):
        target = max(6 if difficulty_estimate != "hard" else 5, target)
        target = min(target, 18 if difficulty_estimate == "medium" else 22)
    elif variant == "alphabet":
        target = max(6 if difficulty_estimate != "hard" else 5, target)
    elif variant == "dice":
        target = max(6 if difficulty_estimate != "hard" else 5, target)
        target = min(target, 14)
    elif variant == "arithmetic":
        target = max(6 if difficulty_estimate != "hard" else 5, target)
        target = min(target, 16)

    if target >= path_length:
        indices = list(range(path_length))
    elif target == 1:
        indices = [0]
    else:
        indices = []
        used = set()
        for i in range(target):
            pos = round(i * (path_length - 1) / (target - 1))
            while pos in used and pos < path_length - 1:
                pos += 1
            if pos in used:
                pos = max(0, pos - 1)
                while pos in used and pos > 0:
                    pos -= 1
            used.add(pos)
            indices.append(pos)
        indices = sorted(set(indices))
        while len(indices) > target:
            indices.pop(len(indices) // 2)
        while len(indices) < target:
            candidate = rng.randint(0, path_length - 1)
            if candidate not in indices:
                indices.append(candidate)
                indices.sort()

    clues: List[Dict[str, int]] = []
    for n, path_idx in enumerate(indices, start=1):
        cell_idx = solution[path_idx]
        x, y = idx_to_xy(cell_idx, width)
        clues.append({"n": n, "x": x, "y": y})
    return clues


def write_summary(levels: List[Dict[str, Any]]) -> None:
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
    ]

    with OUT_SUMMARY_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for lv in levels:
            m = dict(lv["metrics"])
            row = {"id": lv["id"], **{k: m.get(k, "") for k in fields if k != "id"}}
            writer.writerow(row)

    lines = []
    lines.append("| " + " | ".join(fields) + " |")
    lines.append("|" + "|".join(["---"] * len(fields)) + "|")
    for lv in levels:
        m = lv["metrics"]
        row = [str(lv["id"])] + [str(m.get(k, "")) for k in fields[1:]]
        lines.append("| " + " | ".join(row) + " |")
    OUT_SUMMARY_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    OUT_LEVELS_DIR.mkdir(parents=True, exist_ok=True)
    data = json.loads(PACK_PATH.read_text(encoding="utf-8"))
    source_levels = data["levels"]

    chosen = pick_levels(source_levels)
    generated: List[Dict[str, Any]] = []
    for i, entry in enumerate(chosen):
        payload = build_level_payload(entry, i)
        generated.append(payload)
        (OUT_LEVELS_DIR / f"{payload['id']}.json").write_text(
            json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

    pack = {
        "packId": "variant_ab_tests",
        "version": "variant_test_pack_v1",
        "count": len(generated),
        "levels": generated,
    }
    OUT_PACK_PATH.write_text(
        json.dumps(pack, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    write_summary(generated)

    print(f"[OK] generated {len(generated)} levels")
    print(f"[OK] pack: {OUT_PACK_PATH}")
    print(f"[OK] per-level files: {OUT_LEVELS_DIR}")
    print(f"[OK] metrics csv: {OUT_SUMMARY_CSV}")
    print(f"[OK] metrics md: {OUT_SUMMARY_MD}")


if __name__ == "__main__":
    main()
