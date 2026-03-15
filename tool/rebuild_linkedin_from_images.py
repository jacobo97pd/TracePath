from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple

import cv2

from tool.verify_levels_core import (
    LevelDef,
    cell_to_xy,
    detect_clues,
    detect_grid_size_from_image,
    detect_walls,
    edge_set_to_wall_dict,
    normalize_levels,
    parse_levels_file,
    solve_level_with_stats,
    wall_coord_to_edge,
)


def _numeric_suffix(level_id: str) -> Optional[int]:
    digits = ""
    for ch in reversed(level_id):
        if ch.isdigit():
            digits = ch + digits
        elif digits:
            break
    return int(digits) if digits else None


def _normalize_expected_numbers(level: LevelDef) -> List[int]:
    nums = sorted(int(n) for n in level.clues.keys())
    if not nums or nums[0] != 1:
        return []
    if nums != list(range(1, nums[-1] + 1)):
        return []
    return nums


def _detect_expected_from_votes(cells: Sequence[Dict[str, Any]], fallback_count: int) -> List[int]:
    votes: Dict[int, int] = {}
    for c in cells:
        for n, v in (c.get("votes") or {}).items():
            if 1 <= int(n) <= 30:
                votes[int(n)] = votes.get(int(n), 0) + int(v)
    max_contig = 0
    n = 1
    while True:
        if votes.get(n, 0) <= 0:
            break
        max_contig = n
        n += 1
    if max_contig > 0:
        return list(range(1, max_contig + 1))
    if fallback_count > 0:
        return list(range(1, min(30, fallback_count) + 1))
    return []


def _clue_map_from_tuples(tuples: Sequence[Tuple[int, int, int]], expected: Sequence[int]) -> Dict[int, Tuple[int, int]]:
    keep = set(int(v) for v in expected)
    out: Dict[int, Tuple[int, int]] = {}
    for n, x, y in tuples:
        ni = int(n)
        if ni in keep and ni not in out:
            out[ni] = (int(x), int(y))
    return out


def _edge_set_to_pack_walls(edges: Sequence[Tuple[int, int]]) -> List[Dict[str, int]]:
    out = [{"cell1": int(min(a, b)), "cell2": int(max(a, b))} for a, b in edges]
    out.sort(key=lambda d: (d["cell1"], d["cell2"]))
    return out


def _candidate_numeric_image(images_dir: Path, level_num: int) -> Optional[str]:
    for ext in (".png", ".jpeg", ".jpg"):
        name = f"{level_num}{ext}"
        if (images_dir / name).exists():
            return name
    return None


def _resolve_image_file(level_raw: Dict[str, Any], level_num: Optional[int], images_dir: Path) -> Optional[str]:
    if level_num is not None:
        numeric = _candidate_numeric_image(images_dir, level_num)
        if numeric:
            return numeric
    current = str(level_raw.get("imageFile") or "").strip()
    if current and (images_dir / current).exists():
        return current
    return None


def _extract_level_from_image(
    level: LevelDef,
    level_raw: Dict[str, Any],
    image_path: Path,
    run_solver: bool,
) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    bgr = cv2.imread(str(image_path))
    if bgr is None:
        raise RuntimeError(f"Could not read image: {image_path}")
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    grid = detect_grid_size_from_image(gray, preferred_size=None, min_size=6, max_size=7)

    original_expected = _normalize_expected_numbers(level)
    expected = list(original_expected)
    clue_det = detect_clues(
        bgr=bgr,
        gray=gray,
        grid=grid,
        expected_numbers=expected,
        prior_clues=level.clues,
        variant=0,
    )
    detected_cells = len({(int(c["x"]), int(c["y"])) for c in clue_det.cells})
    if not expected or abs(detected_cells - len(expected)) >= 3:
        inferred = _detect_expected_from_votes(clue_det.cells, detected_cells)
        if (not expected) or (len(inferred) >= 3):
            expected = inferred
            clue_det = detect_clues(
                bgr=bgr,
                gray=gray,
                grid=grid,
                expected_numbers=expected,
                prior_clues=level.clues,
                variant=0,
            )

    clues_map = _clue_map_from_tuples(sorted(clue_det.tuples), expected)
    if len(clues_map) > 22:
        clues_map = dict(level.clues)
    if original_expected and len(clues_map) < max(2, len(original_expected) // 2):
        # Hard fallback to previous clues if OCR/assignment is clearly degraded.
        clues_map = dict(level.clues)

    walls = sorted(detect_walls(gray, grid, variant=0))
    level_out = dict(level_raw)
    level_out["size"] = {"w": int(grid.width), "h": int(grid.height)}
    level_out["clues"] = [{"n": int(n), "x": int(x), "y": int(y)} for n, (x, y) in sorted(clues_map.items())]
    level_out["walls"] = _edge_set_to_pack_walls(walls)

    solved_status = "SKIPPED"
    solved_explored = 0
    if run_solver:
        solved = solve_level_with_stats(
            LevelDef(
                id=level.id,
                width=int(grid.width),
                height=int(grid.height),
                clues=clues_map,
                walls=set(walls),
            ),
            strategy="clue_degree",
        )
        solved_status = "SOLVED" if solved.path is not None else "UNSOLVABLE"
        solved_explored = int(solved.stats.explored_nodes)
    report = {
        "id": level.id,
        "image": image_path.name,
        "size": {"w": int(grid.width), "h": int(grid.height)},
        "cluesDetected": len(clues_map),
        "cellsDetected": detected_cells,
        "strongNumbers": list(getattr(clue_det, "strong_numbers", [])),
        "wallsDetected": len(walls),
        "solverStatus": solved_status,
        "solverExplored": solved_explored,
    }
    return level_out, report


def rebuild_pack(levels_json: Path, images_dir: Path, out_json: Path, start_level: int = 14, run_solver: bool = False) -> Path:
    records = parse_levels_file(levels_json)
    levels = normalize_levels(records)
    pack_obj = json.loads(levels_json.read_text(encoding="utf-8"))
    raw_levels: List[Dict[str, Any]]
    if isinstance(pack_obj, dict) and isinstance(pack_obj.get("levels"), list):
        raw_levels = [dict(v) for v in pack_obj["levels"]]
    elif isinstance(pack_obj, list):
        raw_levels = [dict(v) for v in pack_obj]
    else:
        raise RuntimeError("Unsupported levels json shape")

    reports: List[Dict[str, Any]] = []
    for idx, (level, raw) in enumerate(zip(levels, raw_levels), start=1):
        if idx < start_level:
            continue
        num = _numeric_suffix(level.id)
        image_file = _resolve_image_file(raw, num, images_dir)
        if image_file is None:
            reports.append(
                {
                    "id": level.id,
                    "error": "image_not_found",
                    "image": raw.get("imageFile"),
                }
            )
            continue
        raw["imageFile"] = image_file
        image_path = images_dir / image_file
        try:
            rebuilt, rep = _extract_level_from_image(level, raw, image_path, run_solver=run_solver)
        except Exception as exc:  # pragma: no cover - diagnostic path
            reports.append({"id": level.id, "image": image_file, "error": str(exc)})
            print(f"[FAIL] {level.id} image={image_file} error={exc}", flush=True)
            continue
        raw_levels[idx - 1] = rebuilt
        reports.append(rep)
        print(
            f"[OK] {level.id} image={image_file} size={rep['size']['w']}x{rep['size']['h']} "
            f"clues={rep['cluesDetected']} walls={rep['wallsDetected']} solver={rep['solverStatus']}",
            flush=True,
        )

    if isinstance(pack_obj, dict):
        pack_obj["levels"] = raw_levels
    else:
        pack_obj = raw_levels
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(pack_obj, indent=2), encoding="utf-8")
    report_path = out_json.with_suffix(".rebuild_report.json")
    report_path.write_text(json.dumps({"reports": reports}, indent=2), encoding="utf-8")
    return report_path


def main() -> int:
    parser = argparse.ArgumentParser(description="Rebuild LinkedIn pack levels from screenshot images.")
    parser.add_argument("--levels-json", required=True, type=Path)
    parser.add_argument("--images-dir", required=True, type=Path)
    parser.add_argument("--out-json", required=True, type=Path)
    parser.add_argument("--start-level", type=int, default=14)
    parser.add_argument("--solve", action="store_true", help="Run solver check for each rebuilt level.")
    args = parser.parse_args()

    report_path = rebuild_pack(
        levels_json=args.levels_json,
        images_dir=args.images_dir,
        out_json=args.out_json,
        start_level=int(args.start_level),
        run_solver=bool(args.solve),
    )
    print(f"[OK] rebuilt pack: {args.out_json}")
    print(f"[OK] report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
