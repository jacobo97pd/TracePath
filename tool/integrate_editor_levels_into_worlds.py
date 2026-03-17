from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import shutil
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple


ROOT = Path(__file__).resolve().parents[1]
LEVELS_DIR = ROOT / "assets" / "levels"
WORLD_GLOB = "pack_world_*_v1.json"
BACKUP_DIR = ROOT / "backups" / "world_level_imports"


def _load_concatenated_json_objects(path: Path) -> List[Dict[str, Any]]:
    raw = path.read_text(encoding="utf-8")
    decoder = json.JSONDecoder()
    items: List[Dict[str, Any]] = []
    idx = 0
    length = len(raw)
    while idx < length:
        while idx < length and raw[idx].isspace():
            idx += 1
        if idx >= length:
            break
        try:
            obj, end = decoder.raw_decode(raw, idx)
            idx = end
        except json.JSONDecodeError:
            # Recover from stray separators/text by jumping to the next object start.
            next_brace = raw.find("{", idx + 1)
            if next_brace < 0:
                break
            idx = next_brace
            continue
        if isinstance(obj, dict):
            items.append(obj)
    return items


def _parse_size(level: Dict[str, Any]) -> Tuple[int, int]:
    size = level.get("size")
    if isinstance(size, dict):
        w = int(size.get("w", size.get("width", 0)))
        h = int(size.get("h", size.get("height", 0)))
        if w > 0 and h > 0:
            return w, h
    n = int(size)
    return n, n


def _cell_to_xy(cell: int, width: int) -> Tuple[int, int]:
    return cell % width, cell // width


def _canonical_edge(a: int, b: int) -> Tuple[int, int]:
    return (a, b) if a < b else (b, a)


def _expand_walls_to_edges(level: Dict[str, Any], width: int, height: int) -> List[Dict[str, int]]:
    walls = level.get("walls", [])
    edges: set[Tuple[int, int]] = set()
    if isinstance(walls, list):
        for wall in walls:
            if not isinstance(wall, dict):
                continue
            a = int(wall.get("cell1", -1))
            b = int(wall.get("cell2", -1))
            if a < 0 or b < 0:
                continue
            edges.add(_canonical_edge(a, b))
    elif isinstance(walls, dict):
        h_segments = walls.get("h", [])
        v_segments = walls.get("v", [])
        if isinstance(h_segments, list):
            for seg in h_segments:
                if not isinstance(seg, dict):
                    continue
                x = int(seg.get("x", 0))
                y = int(seg.get("y", 0))
                length = int(seg.get("len", 1))
                if y <= 0 or y > height:
                    continue
                for dx in range(length):
                    cx = x + dx
                    if not (0 <= cx < width):
                        continue
                    top = (y - 1) * width + cx
                    bottom = y * width + cx
                    edges.add(_canonical_edge(top, bottom))
        if isinstance(v_segments, list):
            for seg in v_segments:
                if not isinstance(seg, dict):
                    continue
                x = int(seg.get("x", 0))
                y = int(seg.get("y", 0))
                length = int(seg.get("len", 1))
                if x <= 0 or x > width:
                    continue
                for dy in range(length):
                    cy = y + dy
                    if not (0 <= cy < height):
                        continue
                    left = cy * width + (x - 1)
                    right = cy * width + x
                    edges.add(_canonical_edge(left, right))
    return [{"cell1": a, "cell2": b} for a, b in sorted(edges)]


def _normalize_clues(level: Dict[str, Any], width: int, height: int) -> List[Dict[str, int]]:
    raw_clues = level.get("clues", [])
    out: List[Dict[str, int]] = []
    if not isinstance(raw_clues, list):
        return out
    for clue in raw_clues:
        if not isinstance(clue, dict):
            continue
        n = int(clue.get("n", 0))
        x = int(clue.get("x", -1))
        y = int(clue.get("y", -1))
        if n <= 0 or not (0 <= x < width and 0 <= y < height):
            continue
        out.append({"n": n, "x": x, "y": y})
    out.sort(key=lambda c: c["n"])
    return out


def _canonical_hash(width: int, height: int, clues: Sequence[Dict[str, int]], walls: Sequence[Dict[str, int]]) -> str:
    payload = {
        "size": {"w": width, "h": height},
        "clues": list(clues),
        "walls": [{"cell1": int(w["cell1"]), "cell2": int(w["cell2"])} for w in walls],
    }
    raw = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _difficulty_tag(width: int, height: int, clue_count: int) -> str:
    cells = width * height
    density = clue_count / max(1, cells)
    if cells <= 36:
        if density >= 0.28:
            return "d2"
        if density >= 0.20:
            return "d3"
        if density >= 0.15:
            return "d4"
        return "d5"
    if density >= 0.22:
        return "d3"
    if density >= 0.17:
        return "d4"
    return "d5"


def _existing_hashes(world_files: Sequence[Path]) -> set[str]:
    out: set[str] = set()
    for file in world_files:
        payload = json.loads(file.read_text(encoding="utf-8"))
        levels = payload.get("levels", [])
        if not isinstance(levels, list):
            continue
        for level in levels:
            if not isinstance(level, dict):
                continue
            size_w, size_h = _parse_size(level)
            clues = _normalize_clues(level, size_w, size_h)
            walls = _expand_walls_to_edges(level, size_w, size_h)
            out.add(_canonical_hash(size_w, size_h, clues, walls))
    return out


def _next_editor_id(world_files: Sequence[Path]) -> int:
    pattern = re.compile(r"^linkedin-editor-(\d+)$")
    best = 0
    for file in world_files:
        payload = json.loads(file.read_text(encoding="utf-8"))
        levels = payload.get("levels", [])
        if not isinstance(levels, list):
            continue
        for level in levels:
            if not isinstance(level, dict):
                continue
            level_id = str(level.get("id", ""))
            m = pattern.match(level_id)
            if m:
                best = max(best, int(m.group(1)))
    return best + 1


def _backup_world_files(world_files: Sequence[Path]) -> Path:
    stamp = dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = BACKUP_DIR / f"before_import_{stamp}"
    out_dir.mkdir(parents=True, exist_ok=True)
    for file in world_files:
        shutil.copy2(file, out_dir / file.name)
    return out_dir


def _distribute_new_levels(world_files: Sequence[Path], new_levels: List[Dict[str, Any]]) -> None:
    world_payloads: List[Tuple[Path, Dict[str, Any]]] = [
        (file, json.loads(file.read_text(encoding="utf-8"))) for file in world_files
    ]
    world_payloads.sort(key=lambda it: it[0].name)
    if not world_payloads:
        return

    for idx, level in enumerate(new_levels):
        target_path, target_payload = world_payloads[idx % len(world_payloads)]
        levels = target_payload.get("levels", [])
        if not isinstance(levels, list):
            levels = []
            target_payload["levels"] = levels
        levels.append(level)
        target_payload["count"] = len(levels)
        _ = target_path

    for path, payload in world_payloads:
        levels = payload.get("levels", [])
        payload["count"] = len(levels) if isinstance(levels, list) else 0
        path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Import new editor levels and distribute them across world packs without duplicates.",
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to concatenated JSON file (e.g., niveles_linkedin_editor.json).",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(f"[ERROR] Input file not found: {input_path}")

    world_files = sorted(LEVELS_DIR.glob(WORLD_GLOB))
    if not world_files:
        raise SystemExit("[ERROR] No world pack files found.")

    parsed = _load_concatenated_json_objects(input_path)
    if not parsed:
        raise SystemExit("[ERROR] No JSON objects found in input file.")

    backup_dir = _backup_world_files(world_files)
    existing = _existing_hashes(world_files)
    next_id = _next_editor_id(world_files)

    to_insert: List[Dict[str, Any]] = []
    seen_new_hashes: set[str] = set()
    skipped_invalid = 0
    skipped_duplicate = 0

    for raw in parsed:
        try:
            w, h = _parse_size(raw)
            clues = _normalize_clues(raw, w, h)
            if not clues:
                skipped_invalid += 1
                continue
            walls = _expand_walls_to_edges(raw, w, h)
            canonical = _canonical_hash(w, h, clues, walls)
        except Exception:
            skipped_invalid += 1
            continue

        if canonical in existing or canonical in seen_new_hashes:
            skipped_duplicate += 1
            continue

        level_id = f"linkedin-editor-{next_id}"
        next_id += 1
        difficulty = _difficulty_tag(w, h, len(clues))
        level = {
            "id": level_id,
            "size": {"w": w, "h": h},
            "clues": clues,
            "walls": walls,
            "difficultyTag": difficulty,
            "source": "linkedin_editor",
            "source_pack": "pack_linkedin_editor_v1",
            "source_origin": "linkedin_editor",
            "variant": "classic",
            "canonical_hash": canonical,
            "meta": {
                "source_pack": "pack_linkedin_editor_v1",
                "source_origin": "linkedin_editor",
                "variant": "classic",
                "canonical_hash": canonical,
                "imported_from": str(input_path),
            },
        }
        to_insert.append(level)
        seen_new_hashes.add(canonical)

    if to_insert:
        _distribute_new_levels(world_files, to_insert)

    print(f"[OK] backup: {backup_dir}")
    print(f"[OK] parsed objects: {len(parsed)}")
    print(f"[OK] inserted new levels: {len(to_insert)}")
    print(f"[OK] skipped duplicates: {skipped_duplicate}")
    print(f"[OK] skipped invalid: {skipped_invalid}")
    print(f"[OK] world packs updated: {len(world_files)}")


if __name__ == "__main__":
    main()
