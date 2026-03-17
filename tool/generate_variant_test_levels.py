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
    "alphabet_reverse",
    "multiples",
    "multiples_roman",
    "dice",
    "arithmetic",
)

STRATEGIC_VARIANTS = frozenset(
    {
        "alphabet",
        "alphabet_reverse",
        "multiples",
        "roman",
    }
)

_USED_STRATEGIC_FINGERPRINTS: set[str] = set()
_USED_MODEL_COUNTS: Dict[str, int] = {}

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


def _alpha_forward(value: int) -> str:
    # 1 -> A, 26 -> Z, 27 -> AA
    n = max(1, int(value))
    chars: List[str] = []
    while n > 0:
        n -= 1
        chars.append(chr(ord("A") + (n % 26)))
        n //= 26
    return "".join(reversed(chars))


def _alpha_reverse(value: int) -> str:
    # 1 -> Z, 26 -> A, 27 -> ZZ, 28 -> ZY
    n = max(1, int(value))
    chars: List[str] = []
    while n > 0:
        n -= 1
        chars.append(chr(ord("Z") - (n % 26)))
        n //= 26
    return "".join(reversed(chars))


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
    difficulty_estimate: str = "medium",
) -> Tuple[Dict[str, str], Dict[str, Any]]:
    labels: Dict[str, str] = {}
    extra_meta: Dict[str, Any] = {}
    sorted_nums = sorted(clue_numbers)

    if variant == "roman":
        step = 1
        if difficulty_estimate == "hard" and variant_index % 2 == 0:
            step = 2
        for n in sorted_nums:
            labels[str(n)] = romanize(n * step)
        extra_meta["sequence_rule"] = "I, II, III..." if step == 1 else "II, IV, VI..."
        extra_meta["representation"] = "roman"
        extra_meta["roman_step"] = step
        extra_meta["roman_max_value"] = (max(sorted_nums) * step) if sorted_nums else 0

    elif variant == "alphabet":
        start_offset = 0
        for n in sorted_nums:
            labels[str(n)] = _alpha_forward(start_offset + n)
        s1 = _alpha_forward(start_offset + 1)
        s2 = _alpha_forward(start_offset + 2)
        s3 = _alpha_forward(start_offset + 3)
        extra_meta["sequence_rule"] = f"{s1}, {s2}, {s3}..."
        extra_meta["representation"] = "alphabet"
        extra_meta["alphabet_start_char"] = _alpha_forward(start_offset + 1)

    elif variant == "alphabet_reverse":
        start_offset = 0
        for n in sorted_nums:
            labels[str(n)] = _alpha_reverse(start_offset + n)
        s1 = _alpha_reverse(start_offset + 1)
        s2 = _alpha_reverse(start_offset + 2)
        s3 = _alpha_reverse(start_offset + 3)
        extra_meta["sequence_rule"] = f"{s1}, {s2}, {s3}..."
        extra_meta["representation"] = "alphabet_reverse"
        extra_meta["alphabet_start_char"] = _alpha_reverse(start_offset + 1)

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
    source_id = str(src.get("id", "generated"))

    if variant in STRATEGIC_VARIANTS:
        variant_seed_offset = sum((i + 1) * ord(ch) for i, ch in enumerate(variant))
        source_seed_offset = sum((i + 1) * ord(ch) for i, ch in enumerate(source_id))
        base_seed = 8000 + variant_index * 43 + variant_seed_offset + source_seed_offset
        selected: Tuple[int, int, List[int], List[Dict[str, int]], List[Dict[str, int]]] | None = None
        for regen in range(36):
            width, height, solution, walls_list = _generate_strategic_geometry(
                difficulty_estimate=difficulty_estimate,
                variant=variant,
                seed=base_seed + regen * 7919,
            )
            trial_clues = build_clues_from_solution(
                solution=solution,
                width=width,
                difficulty_estimate=difficulty_estimate,
                variant=variant,
                seed=4000 + variant_index * 17 + regen * 271,
                walls=walls_list,
            )
            clues_idx = _clues_to_indices(trial_clues, solution, width)
            ok, exact = _validate_strategic_candidate(
                solution=solution,
                width=width,
                height=height,
                walls=walls_list,
                clue_indices=clues_idx,
            )
            if ok and exact:
                selected = (width, height, solution, walls_list, trial_clues)
                break
        if selected is None:
            raise RuntimeError(
                f"Strategic generation produced invalid puzzle variant={variant} idx={variant_index}"
            )
        width, height, solution, walls_list, clues = selected
        source_id = f"generated_{variant}_{variant_index + 1:03d}"
    else:
        width = int(src["size"]["w"])
        height = int(src["size"]["h"])
        solution = [int(v) for v in src.get("solution", [])]
        walls_list = src.get("walls", [])
        clues = build_clues_from_solution(
            solution=solution,
            width=width,
            difficulty_estimate=difficulty_estimate,
            variant=variant,
            seed=4000 + variant_index * 17,
            walls=walls_list,
        )

    size = width if width == height else {"w": width, "h": height}
    walls_hv = wall_edges_to_hv_segments(walls_list, width, height)
    clue_numbers = [int(c["n"]) for c in clues]
    labels, extra_meta = build_display_labels(
        variant,
        clue_numbers,
        variant_index,
        difficulty_estimate=difficulty_estimate,
    )

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
        "num_walls": len(walls_list),
    }
    for optional_key in (
        "alphabet_start_char",
        "multiple_base",
        "roman_max_value",
        "roman_step",
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
        "roman_step",
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
        "solution": solution,
        "meta": meta,
        "metrics": metrics,
    }


def _generate_strategic_geometry(
    difficulty_estimate: str,
    variant: str,
    seed: int,
) -> Tuple[int, int, List[int], List[Dict[str, int]]]:
    rng = random.Random(seed)
    if variant in {"alphabet", "alphabet_reverse"}:
        # Keep alphabet variants readable (avoid excessively large labels like AG/AW).
        size_options = {
            "easy": [(5, 5)],
            "medium": [(5, 5)],
            "hard": [(5, 5)],
        }
    else:
        size_options = {
            "easy": [(6, 6), (7, 7)],
            "medium": [(7, 7)],
            "hard": [(7, 7)],
        }
    candidates = size_options.get(difficulty_estimate, [(7, 7)])

    fallback_candidate: Tuple[int, int, List[int], List[Dict[str, int]]] | None = None
    for attempt in range(120):
        width, height = rng.choice(candidates)
        solution = _generate_hamiltonian_path(width, height, rng)
        walls = _generate_strategic_walls(
            width=width,
            height=height,
            solution=solution,
            difficulty_estimate=difficulty_estimate,
            rng=rng,
        )
        if not _is_solution_path_valid(width, height, solution, walls):
            continue
        model = _classify_path_model(width, height, solution)
        model_cap = 1 if model == "lane_serpentine" else 10**9
        if _USED_MODEL_COUNTS.get(model, 0) >= model_cap:
            continue
        fp = _strategic_fingerprint(width, height, solution, walls)
        if fp not in _USED_STRATEGIC_FINGERPRINTS:
            _USED_STRATEGIC_FINGERPRINTS.add(fp)
            _USED_MODEL_COUNTS[model] = _USED_MODEL_COUNTS.get(model, 0) + 1
            return width, height, solution, walls
        if fallback_candidate is None:
            fallback_candidate = (width, height, solution, walls)
    if fallback_candidate is not None:
        width, height, solution, walls = fallback_candidate
        _USED_STRATEGIC_FINGERPRINTS.add(_strategic_fingerprint(width, height, solution, walls))
        return width, height, solution, walls
    raise RuntimeError(
        f"Failed to generate strategic geometry for variant={variant} difficulty={difficulty_estimate}"
    )


def _generate_hamiltonian_path(width: int, height: int, rng: random.Random) -> List[int]:
    total = width * height
    adjacency: List[List[int]] = [[] for _ in range(total)]
    for y in range(height):
        for x in range(width):
            cell = y * width + x
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    adjacency[cell].append(ny * width + nx)

    node_budget = 240_000
    explored = 0

    for _ in range(140):
        start = rng.randrange(total)
        visited = [False] * total
        path: List[int] = [start]
        visited[start] = True

        def backtrack(cell: int) -> bool:
            nonlocal explored
            explored += 1
            if explored > node_budget:
                return False
            if len(path) == total:
                return True

            candidates = [n for n in adjacency[cell] if not visited[n]]
            if not candidates:
                return False

            rng.shuffle(candidates)
            candidates.sort(
                key=lambda n: (
                    sum(1 for t in adjacency[n] if not visited[t]),
                    rng.random(),
                )
            )

            for nxt in candidates:
                visited[nxt] = True
                path.append(nxt)
                if backtrack(nxt):
                    return True
                path.pop()
                visited[nxt] = False
            return False

        if backtrack(start):
            if rng.random() < 0.5:
                path.reverse()
            return _random_transform_path(path, width, height, rng)

    # Safe fallback (should be rare): snake plus transforms.
    coords: List[Tuple[int, int]] = []
    for y in range(height):
        xs = range(width) if y % 2 == 0 else range(width - 1, -1, -1)
        for x in xs:
            coords.append((x, y))
    path = [y * width + x for x, y in coords]
    if rng.random() < 0.5:
        path.reverse()
    return _random_transform_path(path, width, height, rng)


def _random_transform_path(
    path: List[int],
    width: int,
    height: int,
    rng: random.Random,
) -> List[int]:
    ops = _symmetry_ops(width, height)
    op = rng.choice(ops)
    transformed: List[int] = []
    for c in path:
        x, y = c % width, c // width
        tx, ty = _apply_symmetry(op, x, y, width, height)
        transformed.append(ty * width + tx)
    return transformed


def _generate_strategic_walls(
    width: int,
    height: int,
    solution: List[int],
    difficulty_estimate: str,
    rng: random.Random,
) -> List[Dict[str, int]]:
    path_edges = set()
    for a, b in zip(solution, solution[1:]):
        lo, hi = (a, b) if a < b else (b, a)
        path_edges.add((lo, hi))

    all_edges: List[Tuple[int, int]] = []
    for y in range(height):
        for x in range(width):
            c = y * width + x
            if x + 1 < width:
                r = y * width + (x + 1)
                all_edges.append((c, r) if c < r else (r, c))
            if y + 1 < height:
                d = (y + 1) * width + x
                all_edges.append((c, d) if c < d else (d, c))

    candidates = [e for e in all_edges if e not in path_edges]
    if not candidates:
        return []

    target_range = {
        "easy": (4, 8),
        "medium": (7, 12),
        "hard": (10, 15),
    }.get(difficulty_estimate, (7, 12))
    target = rng.randint(*target_range)

    path_pos = {cell: i for i, cell in enumerate(solution)}
    free_degree = [0] * (width * height)
    neighbors: List[set[int]] = [set() for _ in range(width * height)]
    for a, b in all_edges:
        neighbors[a].add(b)
        neighbors[b].add(a)
        free_degree[a] += 1
        free_degree[b] += 1

    scored: List[Tuple[float, Tuple[int, int]]] = []
    cx = (width - 1) / 2.0
    cy = (height - 1) / 2.0
    for a, b in candidates:
        ax, ay = a % width, a // width
        bx, by = b % width, b // width
        mx, my = (ax + bx) / 2.0, (ay + by) / 2.0
        center_bonus = 1.0 / (1.0 + abs(mx - cx) + abs(my - cy))
        along_path_gap = abs(path_pos[a] - path_pos[b])
        score = center_bonus * 2.0 + min(6.0, along_path_gap / 4.0) + rng.random() * 0.2
        scored.append((score, (a, b)))
    scored.sort(key=lambda t: t[0], reverse=True)
    edge_to_score = {edge: score for score, edge in scored}
    shuffled_candidates = [edge for _, edge in scored]
    rng.shuffle(shuffled_candidates)
    walls: List[Dict[str, int]] = []
    for a, b in shuffled_candidates:
        if len(walls) >= target:
            break
        score = edge_to_score[(a, b)]
        accept_threshold = 0.30 if difficulty_estimate == "easy" else 0.24
        if rng.random() > min(0.92, accept_threshold + min(0.68, score / 10.0)):
            continue
        min_a = 1 if path_pos[a] in (0, len(solution) - 1) else 2
        min_b = 1 if path_pos[b] in (0, len(solution) - 1) else 2
        if free_degree[a] - 1 < min_a or free_degree[b] - 1 < min_b:
            continue
        free_degree[a] -= 1
        free_degree[b] -= 1
        walls.append({"cell1": a, "cell2": b})

    return walls


def _classify_path_model(width: int, height: int, solution: List[int]) -> str:
    if len(solution) < 3:
        return "other"
    dirs: List[Tuple[int, int]] = []
    for a, b in zip(solution, solution[1:]):
        ax, ay = a % width, a // width
        bx, by = b % width, b // width
        dirs.append((bx - ax, by - ay))
    runs: List[int] = []
    run = 1
    for i in range(1, len(dirs)):
        if dirs[i] == dirs[i - 1]:
            run += 1
        else:
            runs.append(run)
            run = 1
    runs.append(run)

    long_threshold = max(width, height) - 1
    long_runs = sum(1 for r in runs if r >= long_threshold - 1)
    short_runs = sum(1 for r in runs if r <= 2)
    alternating = sum(1 for i in range(1, len(runs)) if runs[i - 1] >= long_threshold - 1 and runs[i] <= 2)
    if (
        len(runs) >= 8
        and long_runs >= 4
        and short_runs >= 3
        and alternating >= 3
    ):
        return "lane_serpentine"
    return "other"


def _symmetry_ops(width: int, height: int) -> List[str]:
    if width == height:
        return [
            "id",
            "rot90",
            "rot180",
            "rot270",
            "flip_x",
            "flip_y",
            "diag",
            "anti_diag",
        ]
    return ["id", "flip_x", "flip_y", "flip_xy"]


def _apply_symmetry(
    op: str,
    x: int,
    y: int,
    width: int,
    height: int,
) -> Tuple[int, int]:
    if op == "id":
        return x, y
    if op == "flip_x":
        return width - 1 - x, y
    if op == "flip_y":
        return x, height - 1 - y
    if op == "flip_xy":
        return width - 1 - x, height - 1 - y
    if op == "rot90":
        return height - 1 - y, x
    if op == "rot180":
        return width - 1 - x, height - 1 - y
    if op == "rot270":
        return y, width - 1 - x
    if op == "diag":
        return y, x
    if op == "anti_diag":
        return width - 1 - y, height - 1 - x
    return x, y


def _strategic_fingerprint(
    width: int,
    height: int,
    solution: List[int],
    walls: List[Dict[str, int]],
) -> str:
    wall_edges: List[Tuple[int, int]] = []
    for w in walls:
        a = int(w["cell1"])
        b = int(w["cell2"])
        wall_edges.append((a, b) if a < b else (b, a))

    base_solution_xy = [(c % width, c // width) for c in solution]
    ops = _symmetry_ops(width, height)
    variants: List[str] = []
    for op in ops:
        transformed_solution: List[int] = []
        for x, y in base_solution_xy:
            tx, ty = _apply_symmetry(op, x, y, width, height)
            transformed_solution.append(ty * width + tx)
        transformed_walls: List[Tuple[int, int]] = []
        for a, b in wall_edges:
            ax, ay = a % width, a // width
            bx, by = b % width, b // width
            tax, tay = _apply_symmetry(op, ax, ay, width, height)
            tbx, tby = _apply_symmetry(op, bx, by, width, height)
            ta = tay * width + tax
            tb = tby * width + tbx
            transformed_walls.append((ta, tb) if ta < tb else (tb, ta))
        transformed_walls.sort()
        solution_key = ",".join(map(str, transformed_solution))
        wall_key = ";".join(f"{a}-{b}" for a, b in transformed_walls)
        variants.append(f"{width}x{height}|{solution_key}|{wall_key}")
    return min(variants)


def _is_solution_path_valid(
    width: int,
    height: int,
    solution: List[int],
    walls: List[Dict[str, int]],
) -> bool:
    total = width * height
    if len(solution) != total:
        return False
    if len(set(solution)) != total:
        return False
    blocked = set()
    for w in walls:
        a = int(w["cell1"])
        b = int(w["cell2"])
        blocked.add((a, b) if a < b else (b, a))
    for a, b in zip(solution, solution[1:]):
        ax, ay = a % width, a // width
        bx, by = b % width, b // width
        if abs(ax - bx) + abs(ay - by) != 1:
            return False
        lo, hi = (a, b) if a < b else (b, a)
        if (lo, hi) in blocked:
            return False
    return True


def _clues_to_indices(
    clues: List[Dict[str, int]],
    solution: List[int],
    width: int,
) -> List[int]:
    pos = {cell: i for i, cell in enumerate(solution)}
    ordered = sorted(clues, key=lambda c: int(c.get("n", 0)))
    out: List[int] = []
    for c in ordered:
        x = int(c["x"])
        y = int(c["y"])
        cell = y * width + x
        if cell in pos:
            out.append(pos[cell])
    return out


def build_clues_from_solution(
    solution: List[int],
    width: int,
    difficulty_estimate: str,
    variant: str,
    seed: int,
    walls: List[Dict[str, int]] | None = None,
) -> List[Dict[str, int]]:
    if not solution:
        return []

    if variant not in STRATEGIC_VARIANTS:
        return _build_clues_legacy(solution, width, difficulty_estimate, variant, seed)

    rng = random.Random(seed)
    path_length = len(solution)
    height = path_length // width if width > 0 else 0
    wall_edges = list(walls or [])

    if difficulty_estimate == "easy":
        ratio = rng.uniform(0.20, 0.27)
        min_clues = 6
    elif difficulty_estimate == "medium":
        ratio = rng.uniform(0.14, 0.21)
        min_clues = 5
    else:
        ratio = rng.uniform(0.10, 0.16)
        min_clues = 4

    target = max(min_clues, min(path_length, round(path_length * ratio)))

    for attempt in range(10):
        clue_indices = _build_strategic_indices(
            path_length=path_length,
            target=target,
            rng=rng,
            include_end=True,
        )

        for reinforce in range(10):
            ok, exact_match = _validate_strategic_candidate(
                solution=solution,
                width=width,
                height=height,
                walls=wall_edges,
                clue_indices=clue_indices,
            )
            if ok and exact_match:
                return _indices_to_clues(clue_indices, solution, width)
            clue_indices = _add_strategic_index(
                clue_indices=clue_indices,
                path_length=path_length,
                rng=rng,
                force_end=reinforce >= 5,
            )
            if len(clue_indices) >= path_length:
                break

    return _build_clues_legacy(solution, width, difficulty_estimate, variant, seed)


def _build_clues_legacy(
    solution: List[int],
    width: int,
    difficulty_estimate: str,
    variant: str,
    seed: int,
) -> List[Dict[str, int]]:
    path_length = len(solution)
    rng = random.Random(seed)

    if difficulty_estimate == "easy":
        ratio = rng.uniform(0.30, 0.45)
    elif difficulty_estimate == "medium":
        ratio = rng.uniform(0.20, 0.32)
    else:
        ratio = rng.uniform(0.12, 0.22)

    target = max(4, min(path_length, round(path_length * ratio)))

    if variant == "roman":
        if difficulty_estimate == "easy":
            target = min(target, 10)
        elif difficulty_estimate == "medium":
            target = min(target, 20)
        target = max(5, target)
    elif variant in ("multiples_roman",):
        target = max(6 if difficulty_estimate != "hard" else 5, target)
        target = min(target, 18 if difficulty_estimate == "medium" else 22)
    elif variant in ("alphabet", "alphabet_reverse"):
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

    if indices:
        if 0 not in indices:
            indices.insert(0, 0)
        if (path_length - 1) not in indices:
            indices.append(path_length - 1)
    indices = sorted(set(indices))

    return _indices_to_clues(indices, solution, width)


def _indices_to_clues(
    clue_indices: List[int],
    solution: List[int],
    width: int,
) -> List[Dict[str, int]]:
    clues: List[Dict[str, int]] = []
    for n, path_idx in enumerate(sorted(set(clue_indices)), start=1):
        cell_idx = solution[path_idx]
        x, y = idx_to_xy(cell_idx, width)
        clues.append({"n": n, "x": x, "y": y})
    return clues


def _build_strategic_indices(
    path_length: int,
    target: int,
    rng: random.Random,
    include_end: bool,
) -> List[int]:
    if path_length <= 0:
        return []
    target = max(2, min(target, path_length))
    picks = {0}
    if include_end:
        picks.add(path_length - 1)

    anchor_templates = [
        [0.18, 0.44, 0.72, 0.88],
        [0.16, 0.39, 0.63, 0.86],
        [0.21, 0.50, 0.74, 0.90],
        [0.14, 0.35, 0.58, 0.82],
    ]
    anchors = rng.choice(anchor_templates)
    for frac in anchors:
        if len(picks) >= target:
            break
        jitter = rng.uniform(-0.06, 0.06)
        idx = int(round((path_length - 1) * max(0.0, min(1.0, frac + jitter))))
        picks.add(max(1, min(path_length - 2, idx)))

    while len(picks) < target:
        ordered = sorted(picks)
        best_a, best_b = 0, path_length - 1
        best_gap = -1
        for a, b in zip(ordered, ordered[1:]):
            gap = b - a
            if gap > best_gap:
                best_gap = gap
                best_a, best_b = a, b
        if best_gap <= 1:
            break
        mid = (best_a + best_b) // 2
        picks.add(mid)

    return sorted(picks)


def _add_strategic_index(
    clue_indices: List[int],
    path_length: int,
    rng: random.Random,
    force_end: bool = False,
) -> List[int]:
    picks = sorted(set(clue_indices))
    if force_end and (path_length - 1) not in picks:
        picks.append(path_length - 1)
        return sorted(set(picks))
    if len(picks) >= path_length:
        return picks
    best_gap = -1
    best_pair = (0, path_length - 1)
    for a, b in zip(picks, picks[1:]):
        if b - a > best_gap:
            best_gap = b - a
            best_pair = (a, b)
    if best_gap <= 1:
        candidate = rng.randint(0, path_length - 1)
    else:
        candidate = (best_pair[0] + best_pair[1]) // 2
    picks.append(candidate)
    return sorted(set(picks))


def _validate_strategic_candidate(
    solution: List[int],
    width: int,
    height: int,
    walls: List[Dict[str, int]],
    clue_indices: List[int],
) -> Tuple[bool, bool]:
    if not clue_indices or clue_indices[0] != 0:
        return False, False
    clue_cells = [solution[i] for i in clue_indices]
    count, found_path, aborted = _count_solution_paths(
        width=width,
        height=height,
        walls=walls,
        clue_cells=clue_cells,
        max_solutions=2,
        max_nodes=220_000,
    )
    if aborted:
        return False, False
    if count != 1 or found_path is None:
        return False, False
    return True, found_path == solution


def _count_solution_paths(
    width: int,
    height: int,
    walls: List[Dict[str, int]],
    clue_cells: List[int],
    max_solutions: int,
    max_nodes: int,
) -> Tuple[int, List[int] | None, bool]:
    total = width * height
    if total <= 0 or not clue_cells:
        return 0, None, False
    start = clue_cells[0]
    clue_pos = {c: i for i, c in enumerate(clue_cells)}
    blocked = set()
    for w in walls:
        a = int(w["cell1"])
        b = int(w["cell2"])
        if a > b:
            a, b = b, a
        blocked.add((a, b))

    adjacency: List[List[int]] = [[] for _ in range(total)]
    for y in range(height):
        for x in range(width):
            cell = y * width + x
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < width and 0 <= ny < height):
                    continue
                nxt = ny * width + nx
                a, b = (cell, nxt) if cell < nxt else (nxt, cell)
                if (a, b) in blocked:
                    continue
                adjacency[cell].append(nxt)

    visited = [False] * total
    path = [start]
    visited[start] = True
    clue_reached = 0
    solutions = 0
    first_solution: List[int] | None = None
    explored = 0
    aborted = False

    def can_enter(cell: int, current_clue: int) -> bool:
        clue_idx = clue_pos.get(cell)
        if clue_idx is None:
            return True
        return clue_idx <= current_clue + 1

    def dfs(cell: int, depth: int, current_clue: int) -> None:
        nonlocal solutions, first_solution, explored, aborted
        if solutions >= max_solutions or aborted:
            return
        explored += 1
        if explored > max_nodes:
            aborted = True
            return
        if depth == total:
            if current_clue == len(clue_cells) - 1:
                solutions += 1
                if first_solution is None:
                    first_solution = list(path)
            return

        neighbors = [n for n in adjacency[cell] if not visited[n] and can_enter(n, current_clue)]
        neighbors.sort(key=lambda n: sum(1 for t in adjacency[n] if not visited[t]))
        next_required = clue_cells[current_clue + 1] if current_clue + 1 < len(clue_cells) else -1
        if next_required in neighbors:
            neighbors.sort(key=lambda n: 0 if n == next_required else 1)

        for nxt in neighbors:
            visited[nxt] = True
            path.append(nxt)
            next_clue = current_clue
            if current_clue + 1 < len(clue_cells) and nxt == clue_cells[current_clue + 1]:
                next_clue += 1
            dfs(nxt, depth + 1, next_clue)
            path.pop()
            visited[nxt] = False
            if solutions >= max_solutions or aborted:
                return

    dfs(start, 1, clue_reached)
    return solutions, first_solution, aborted


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
