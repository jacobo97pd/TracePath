from __future__ import annotations

import csv
import hashlib
import json
import random
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Set, Tuple


ROOT = Path(__file__).resolve().parents[1]
LEVELS_DIR = ROOT / "assets" / "levels"
INPUT_PACKS = [
    LEVELS_DIR / "pack_all_v1.json",
    LEVELS_DIR / "pack_linkedin_v1.json",
    LEVELS_DIR / "pack_linkedin_editor_v1.json",
    LEVELS_DIR / "pack_linkedin_js_generated_v1.json",
]
BACKUP_ROOT = ROOT / "backups" / "packs"
OUTPUT_DIR = ROOT / "exports" / "master_pack"
MASTER_PACK_PATH = LEVELS_DIR / "master_pack_v1.json"
MASTER_PACK_COPY_PATH = OUTPUT_DIR / "master_pack_v1.json"
GROUPED_PREVIEW_PATH = OUTPUT_DIR / "master_pack_grouped_preview.json"
METRICS_CSV_PATH = OUTPUT_DIR / "master_pack_metrics.csv"
DUPLICATES_CSV_PATH = OUTPUT_DIR / "master_pack_duplicates.csv"
REJECTED_CSV_PATH = OUTPUT_DIR / "master_pack_rejected.csv"
SUMMARY_MD_PATH = OUTPUT_DIR / "master_pack_summary.md"
SHUFFLE_SEED = 20260316

Edge = Tuple[int, int]


@dataclass
class NormalizedLevel:
    id: str
    width: int
    height: int
    clues: List[Dict[str, int]]
    walls: List[Dict[str, int]]
    difficulty: str
    source_pack: str
    source_origin: str
    variant: str
    metadata: Dict[str, Any]
    canonical_hash: str
    source_order: int
    solution: List[int]
    raw: Dict[str, Any]


@dataclass
class ValidationResult:
    valid: bool
    reason: str
    solutions_found: int = 0


def canonical_edge(a: int, b: int) -> Edge:
    return (a, b) if a < b else (b, a)


def xy_to_cell(x: int, y: int, width: int) -> int:
    return y * width + x


def cell_to_xy(cell: int, width: int) -> Tuple[int, int]:
    return (cell % width, cell // width)


def is_edge_valid(edge: Edge, width: int, height: int) -> bool:
    a, b = canonical_edge(edge[0], edge[1])
    total = width * height
    if a < 0 or b < 0 or a >= total or b >= total:
        return False
    if b - a == 1:
        ax, ay = cell_to_xy(a, width)
        bx, by = cell_to_xy(b, width)
        return ay == by and bx == ax + 1
    if b - a == width:
        ax, ay = cell_to_xy(a, width)
        bx, by = cell_to_xy(b, width)
        return ax == bx and by == ay + 1
    return False


def load_pack(path: Path) -> Tuple[Dict[str, Any], List[Dict[str, Any]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    levels = payload.get("levels", [])
    if not isinstance(levels, list):
        raise ValueError(f"Pack has no levels list: {path}")
    return payload, [dict(v) for v in levels if isinstance(v, dict)]


def parse_size(raw: Dict[str, Any]) -> Tuple[int, int]:
    size = raw.get("size")
    if isinstance(size, dict):
        w = size.get("w", size.get("width"))
        h = size.get("h", size.get("height"))
        if w is not None and h is not None:
            return int(w), int(h)
    if isinstance(size, (int, float)):
        n = int(size)
        return n, n
    w = raw.get("w", raw.get("width"))
    h = raw.get("h", raw.get("height"))
    if w is not None and h is not None:
        return int(w), int(h)
    raise ValueError("missing size")


def parse_clues(raw: Dict[str, Any], width: int, height: int) -> List[Dict[str, int]]:
    clues = raw.get("clues")
    parsed: List[Dict[str, int]] = []
    if isinstance(clues, list):
        for clue in clues:
            if not isinstance(clue, dict) or "n" not in clue:
                continue
            x = int(clue.get("x", clue.get("col", -1)))
            y = int(clue.get("y", clue.get("row", -1)))
            n = int(clue["n"])
            parsed.append({"n": n, "x": x, "y": y})
    elif isinstance(raw.get("numbers"), dict):
        for cell_raw, n_raw in dict(raw["numbers"]).items():
            cell = int(cell_raw)
            n = int(n_raw)
            x, y = cell_to_xy(cell, width)
            parsed.append({"n": n, "x": x, "y": y})

    out: List[Dict[str, int]] = []
    seen_numbers: Set[int] = set()
    seen_cells: Set[Tuple[int, int]] = set()
    for clue in sorted(parsed, key=lambda c: c["n"]):
        x = clue["x"]
        y = clue["y"]
        n = clue["n"]
        if not (0 <= x < width and 0 <= y < height):
            raise ValueError("clue out of bounds")
        if n <= 0:
            raise ValueError("non-positive clue number")
        if n in seen_numbers:
            raise ValueError("duplicate clue number")
        if (x, y) in seen_cells:
            raise ValueError("duplicate clue cell")
        seen_numbers.add(n)
        seen_cells.add((x, y))
        out.append({"n": n, "x": x, "y": y})
    if not out:
        raise ValueError("no clues")
    return out


def parse_walls(raw: Dict[str, Any], width: int, height: int) -> List[Dict[str, int]]:
    walls_raw = raw.get("walls", [])
    edges: Set[Edge] = set()
    if isinstance(walls_raw, list):
        for wall in walls_raw:
            if not isinstance(wall, dict):
                continue
            a = int(wall["cell1"])
            b = int(wall["cell2"])
            edge = canonical_edge(a, b)
            if not is_edge_valid(edge, width, height):
                raise ValueError("invalid wall edge")
            edges.add(edge)
    elif isinstance(walls_raw, dict):
        h_segments = list(walls_raw.get("h", []))
        v_segments = list(walls_raw.get("v", []))
        for seg in h_segments:
            if not isinstance(seg, dict):
                continue
            x = int(seg.get("x", 0))
            y = int(seg.get("y", 0))
            length = int(seg.get("len", 1))
            if y <= 0 or y > height:
                raise ValueError("horizontal wall segment out of bounds")
            for dx in range(length):
                cx = x + dx
                if not (0 <= cx < width):
                    raise ValueError("horizontal wall segment out of bounds")
                top = (y - 1) * width + cx
                bottom = y * width + cx
                edges.add(canonical_edge(top, bottom))
        for seg in v_segments:
            if not isinstance(seg, dict):
                continue
            x = int(seg.get("x", 0))
            y = int(seg.get("y", 0))
            length = int(seg.get("len", 1))
            if x <= 0 or x > width:
                raise ValueError("vertical wall segment out of bounds")
            for dy in range(length):
                cy = y + dy
                if not (0 <= cy < height):
                    raise ValueError("vertical wall segment out of bounds")
                left = cy * width + (x - 1)
                right = cy * width + x
                edges.add(canonical_edge(left, right))
    else:
        raise ValueError("invalid walls format")

    return [{"cell1": a, "cell2": b} for a, b in sorted(edges)]


def normalize_level(
    raw: Dict[str, Any],
    *,
    source_pack: str,
    source_order: int,
) -> NormalizedLevel:
    width, height = parse_size(raw)
    clues = parse_clues(raw, width, height)
    walls = parse_walls(raw, width, height)
    meta = dict(raw.get("meta", {})) if isinstance(raw.get("meta"), dict) else {}
    variant = str(meta.get("variant") or raw.get("variant") or "classic").strip() or "classic"
    difficulty = str(raw.get("difficultyTag") or meta.get("difficulty_target") or "unknown").strip() or "unknown"
    source_origin = str(raw.get("origin") or raw.get("source") or meta.get("source_level_id") or "").strip() or "unknown"
    solution = [int(v) for v in raw.get("solution", [])] if isinstance(raw.get("solution"), list) else []
    canonical_payload = {
        "size": {"w": width, "h": height},
        "clues": clues,
        "walls": walls,
    }
    canonical_hash = hashlib.sha256(
        json.dumps(canonical_payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return NormalizedLevel(
        id=str(raw.get("id") or f"{source_pack}-{source_order}"),
        width=width,
        height=height,
        clues=clues,
        walls=walls,
        difficulty=difficulty,
        source_pack=source_pack,
        source_origin=source_origin,
        variant=variant,
        metadata=meta,
        canonical_hash=canonical_hash,
        source_order=source_order,
        solution=solution,
        raw=raw,
    )


def build_adjacency(width: int, height: int, walls: Sequence[Dict[str, int]]) -> List[List[int]]:
    blocked = {canonical_edge(int(w["cell1"]), int(w["cell2"])) for w in walls}
    total = width * height
    adj: List[List[int]] = [[] for _ in range(total)]
    for cell in range(total):
        x, y = cell_to_xy(cell, width)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                nxt = xy_to_cell(nx, ny, width)
                if canonical_edge(cell, nxt) not in blocked:
                    adj[cell].append(nxt)
        adj[cell].sort()
    return adj


def count_solutions(level: NormalizedLevel, max_solutions: int = 2) -> int:
    clue_nums = [c["n"] for c in level.clues]
    if clue_nums != list(range(1, max(clue_nums) + 1)):
        return 0

    total = level.width * level.height
    clue_by_num = {c["n"]: xy_to_cell(c["x"], c["y"], level.width) for c in level.clues}
    clue_by_cell = {cell: n for n, cell in clue_by_num.items()}
    start = clue_by_num[1]
    end = clue_by_num[max(clue_nums)]
    adj = build_adjacency(level.width, level.height, level.walls)
    path: List[int] = [start]
    dead: Set[Tuple[int, int, int]] = set()
    solutions = 0
    node_limit = 220000 if total >= 42 else 120000
    explored = 0

    def parity_prune(cur: int) -> bool:
        left = total - len(path)
        cx, cy = cell_to_xy(cur, level.width)
        ex, ey = cell_to_xy(end, level.width)
        dist = abs(cx - ex) + abs(cy - ey)
        return dist > left or ((left - dist) % 2 != 0)

    def conn_prune(cur: int, mask: int) -> bool:
        want = 1 + (total - int(mask.bit_count()))
        stack = [cur]
        seen = {cur}
        while stack:
            node = stack.pop()
            for nb in adj[node]:
                if nb != cur and ((mask >> nb) & 1):
                    continue
                if nb in seen:
                    continue
                seen.add(nb)
                stack.append(nb)
        return len(seen) != want or end not in seen

    def dead_cell_prune(cur: int, mask: int, expected: int) -> bool:
        if expected <= max(clue_nums) and ((mask >> clue_by_num[expected]) & 1):
            return True
        for cell in range(total):
            if (mask >> cell) & 1:
                continue
            avail = 0
            for nb in adj[cell]:
                if nb != cur and ((mask >> nb) & 1):
                    continue
                cn = clue_by_cell.get(nb)
                if cn is not None and cn > expected:
                    continue
                avail += 1
            if cell == end:
                if len(path) < total - 1 and avail == 0:
                    return True
            elif avail == 0:
                return True
        return False

    def next_clue_reach_prune(cur: int, mask: int, expected: int) -> bool:
        if expected > max(clue_nums):
            return False
        target = clue_by_num[expected]
        if (mask >> target) & 1:
            return True
        queue = [cur]
        seen = {cur}
        i = 0
        while i < len(queue):
            node = queue[i]
            i += 1
            if node == target:
                return False
            for nb in adj[node]:
                if nb in seen:
                    continue
                if nb != target and ((mask >> nb) & 1):
                    continue
                cn = clue_by_cell.get(nb)
                if cn is not None and nb != target and cn > expected:
                    continue
                seen.add(nb)
                queue.append(nb)
        return True

    def degree(cell: int, next_mask: int) -> int:
        return sum(1 for nb in adj[cell] if ((next_mask >> nb) & 1) == 0)

    def dfs(cur: int, mask: int, expected: int) -> None:
        nonlocal explored, solutions
        if solutions >= max_solutions:
            return
        explored += 1
        if explored > node_limit:
            return
        state = (cur, mask, expected)
        if state in dead:
            return
        if len(path) == total:
            if cur == end and expected == max(clue_nums) + 1:
                solutions += 1
            else:
                dead.add(state)
            return
        if cur == end:
            dead.add(state)
            return
        if parity_prune(cur) or conn_prune(cur, mask) or dead_cell_prune(cur, mask, expected) or next_clue_reach_prune(cur, mask, expected):
            dead.add(state)
            return

        ex, ey = cell_to_xy(end, level.width)
        candidates: List[Tuple[int, int, int, int]] = []
        for nb in adj[cur]:
            if (mask >> nb) & 1:
                continue
            if nb == end and len(path) != total - 1:
                continue
            cn = clue_by_cell.get(nb)
            if cn is not None and cn != expected:
                continue
            nx, ny = cell_to_xy(nb, level.width)
            candidates.append(
                (
                    0 if cn == expected else 1,
                    degree(nb, mask | (1 << nb)),
                    abs(nx - ex) + abs(ny - ey),
                    nb,
                )
            )
        candidates.sort()
        for _, _, _, nb in candidates:
            cn = clue_by_cell.get(nb)
            next_expected = expected + 1 if cn == expected else expected
            path.append(nb)
            dfs(nb, mask | (1 << nb), next_expected)
            path.pop()
            if solutions >= max_solutions:
                return
        dead.add(state)

    dfs(start, 1 << start, 2)
    return solutions


def validate_level(level: NormalizedLevel) -> ValidationResult:
    if level.width <= 0 or level.height <= 0:
        return ValidationResult(False, "invalid_size")
    if not any(c["n"] == 1 for c in level.clues):
        return ValidationResult(False, "missing_start")
    try:
        solutions = count_solutions(level, max_solutions=2)
    except Exception as exc:
        return ValidationResult(False, f"solver_error:{exc}")
    if solutions != 1:
        reason = "unsolvable" if solutions == 0 else "ambiguous"
        return ValidationResult(False, reason, solutions_found=solutions)
    return ValidationResult(True, "ok", solutions_found=solutions)


def normalized_to_output(level: NormalizedLevel) -> Dict[str, Any]:
    out: Dict[str, Any] = {
        "id": level.id,
        "size": {"w": level.width, "h": level.height},
        "clues": level.clues,
        "walls": level.walls,
        "difficultyTag": level.difficulty,
        "source": level.source_origin,
        "source_pack": level.source_pack,
        "source_origin": level.source_origin,
        "variant": level.variant,
        "canonical_hash": level.canonical_hash,
        "meta": dict(level.metadata),
    }
    if level.solution:
        out["solution"] = level.solution
    out["meta"]["source_pack"] = level.source_pack
    out["meta"]["source_origin"] = level.source_origin
    out["meta"]["variant"] = level.variant
    out["meta"]["canonical_hash"] = level.canonical_hash
    return out


def choose_representative(levels: Sequence[NormalizedLevel]) -> NormalizedLevel:
    def score(level: NormalizedLevel) -> Tuple[int, int, int]:
        has_solution = 1 if level.solution else 0
        meta_size = len(level.metadata)
        source_priority = {
            "pack_all_v1": 4,
            "pack_linkedin_editor_v1": 3,
            "pack_linkedin_v1": 2,
            "pack_linkedin_js_generated_v1": 1,
        }.get(level.source_pack, 0)
        return (has_solution, meta_size, source_priority)

    return sorted(levels, key=lambda lv: (score(lv), -lv.source_order), reverse=True)[0]


def write_csv(path: Path, rows: Iterable[Dict[str, Any]], fieldnames: Sequence[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def build_grouped_preview(levels: Sequence[Dict[str, Any]]) -> Dict[str, Any]:
    grouped: Dict[str, Dict[str, List[str]]] = {
        "by_size": defaultdict(list),
        "by_difficulty": defaultdict(list),
        "by_variant": defaultdict(list),
        "by_source_origin": defaultdict(list),
    }
    for level in levels:
        size = level["size"]
        size_key = f'{size["w"]}x{size["h"]}'
        grouped["by_size"][size_key].append(level["id"])
        grouped["by_difficulty"][str(level.get("difficultyTag", "unknown"))].append(level["id"])
        grouped["by_variant"][str(level.get("variant", "classic"))].append(level["id"])
        grouped["by_source_origin"][str(level.get("source_origin", "unknown"))].append(level["id"])
    return {
        key: {k: sorted(v) for k, v in sorted(value.items())}
        for key, value in grouped.items()
    }


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    normalized_levels: List[NormalizedLevel] = []
    rejected_rows: List[Dict[str, Any]] = []
    total_read = 0

    for pack_path in INPUT_PACKS:
        payload, levels = load_pack(pack_path)
        pack_name = pack_path.stem
        for idx, raw in enumerate(levels, start=1):
            total_read += 1
            try:
                normalized_levels.append(
                    normalize_level(raw, source_pack=pack_name, source_order=idx)
                )
            except Exception as exc:
                rejected_rows.append(
                    {
                        "id": str(raw.get("id", f"{pack_name}-{idx}")),
                        "source_pack": pack_name,
                        "source_origin": str(raw.get("origin") or raw.get("source") or "unknown"),
                        "variant": str((raw.get("meta") or {}).get("variant") if isinstance(raw.get("meta"), dict) else raw.get("variant") or "classic"),
                        "reason": f"normalize_error:{exc}",
                    }
                )

    by_hash: Dict[str, List[NormalizedLevel]] = defaultdict(list)
    for level in normalized_levels:
        by_hash[level.canonical_hash].append(level)

    duplicates_rows: List[Dict[str, Any]] = []
    unique_candidates: List[NormalizedLevel] = []
    for canonical_hash, group in sorted(by_hash.items()):
        chosen = choose_representative(group)
        unique_candidates.append(chosen)
        for level in group:
            if level is chosen:
                continue
            duplicates_rows.append(
                {
                    "id": level.id,
                    "source_pack": level.source_pack,
                    "source_origin": level.source_origin,
                    "variant": level.variant,
                    "canonical_hash": canonical_hash,
                    "dedupe_reason": f"duplicate_of:{chosen.id}",
                }
            )

    valid_levels: List[NormalizedLevel] = []
    for level in unique_candidates:
        result = validate_level(level)
        if result.valid:
            valid_levels.append(level)
            continue
        rejected_rows.append(
            {
                "id": level.id,
                "source_pack": level.source_pack,
                "source_origin": level.source_origin,
                "variant": level.variant,
                "reason": result.reason,
            }
        )

    final_levels = [normalized_to_output(level) for level in valid_levels]
    rng = random.Random(SHUFFLE_SEED)
    rng.shuffle(final_levels)

    master_pack = {
        "packId": "master",
        "version": "master_pack_v1",
        "count": len(final_levels),
        "shuffle_seed": SHUFFLE_SEED,
        "source_packs": [p.stem for p in INPUT_PACKS],
        "levels": final_levels,
    }
    MASTER_PACK_PATH.write_text(json.dumps(master_pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    MASTER_PACK_COPY_PATH.write_text(json.dumps(master_pack, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    metrics_rows = [
        {
            "id": level["id"],
            "size": f'{level["size"]["w"]}x{level["size"]["h"]}',
            "difficulty": level.get("difficultyTag", "unknown"),
            "source_pack": level.get("source_pack", "unknown"),
            "source_origin": level.get("source_origin", "unknown"),
            "variant": level.get("variant", "classic"),
            "num_clues": len(level.get("clues", [])),
            "num_walls": len(level.get("walls", [])),
            "canonical_hash": level.get("canonical_hash", ""),
        }
        for level in final_levels
    ]
    write_csv(
        METRICS_CSV_PATH,
        metrics_rows,
        ["id", "size", "difficulty", "source_pack", "source_origin", "variant", "num_clues", "num_walls", "canonical_hash"],
    )
    write_csv(
        DUPLICATES_CSV_PATH,
        duplicates_rows,
        ["id", "source_pack", "source_origin", "variant", "canonical_hash", "dedupe_reason"],
    )
    write_csv(
        REJECTED_CSV_PATH,
        rejected_rows,
        ["id", "source_pack", "source_origin", "variant", "reason"],
    )

    grouped_preview = build_grouped_preview(final_levels)
    GROUPED_PREVIEW_PATH.write_text(json.dumps(grouped_preview, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    size_dist = Counter(row["size"] for row in metrics_rows)
    difficulty_dist = Counter(row["difficulty"] for row in metrics_rows)
    origin_dist = Counter(row["source_origin"] for row in metrics_rows)
    variant_dist = Counter(row["variant"] for row in metrics_rows)
    source_pack_dist = Counter(row["source_pack"] for row in metrics_rows)

    summary_lines = [
        "# Master Pack Summary",
        "",
        f"- Levels read: {total_read}",
        f"- Levels normalized: {len(normalized_levels)}",
        f"- Unique candidates after dedupe: {len(unique_candidates)}",
        f"- Valid levels in master pack: {len(final_levels)}",
        f"- Duplicates removed: {len(duplicates_rows)}",
        f"- Rejected levels: {len(rejected_rows)}",
        f"- Shuffle seed: {SHUFFLE_SEED}",
        "",
        "## Distribution by Size",
        "",
    ]
    summary_lines.extend(f"- {k}: {v}" for k, v in sorted(size_dist.items()))
    summary_lines.extend(["", "## Distribution by Difficulty", ""])
    summary_lines.extend(f"- {k}: {v}" for k, v in sorted(difficulty_dist.items()))
    summary_lines.extend(["", "## Distribution by Source Pack", ""])
    summary_lines.extend(f"- {k}: {v}" for k, v in sorted(source_pack_dist.items()))
    summary_lines.extend(["", "## Distribution by Source Origin", ""])
    summary_lines.extend(f"- {k}: {v}" for k, v in sorted(origin_dist.items()))
    summary_lines.extend(["", "## Distribution by Variant", ""])
    summary_lines.extend(f"- {k}: {v}" for k, v in sorted(variant_dist.items()))
    SUMMARY_MD_PATH.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

    print(f"[OK] backup root expected under: {BACKUP_ROOT}")
    print(f"[OK] levels read: {total_read}")
    print(f"[OK] valid master levels: {len(final_levels)}")
    print(f"[OK] duplicates removed: {len(duplicates_rows)}")
    print(f"[OK] rejected: {len(rejected_rows)}")
    print(f"[OK] master pack: {MASTER_PACK_PATH}")
    print(f"[OK] audit dir: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
