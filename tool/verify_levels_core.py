from __future__ import annotations

import json
import os
import re
import time
import hashlib
from dataclasses import dataclass, replace
from itertools import combinations
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Set, Tuple

import cv2
import numpy as np
import pytesseract
from PIL import Image, ImageDraw
from scipy.optimize import linear_sum_assignment

Coord = Tuple[int, int]
Edge = Tuple[int, int]
WallCoord = Tuple[str, int, int]


@dataclass(frozen=True)
class LevelDef:
    id: str
    width: int
    height: int
    clues: Dict[int, Coord]
    walls: Set[Edge]
    image_hint: Optional[str] = None
    raw: Optional[Dict[str, Any]] = None


@dataclass
class GridDetection:
    bbox: Tuple[int, int, int, int]
    x_lines: List[int]
    y_lines: List[int]
    score: float

    @property
    def width(self) -> int:
        return len(self.x_lines) - 1

    @property
    def height(self) -> int:
        return len(self.y_lines) - 1


@dataclass
class ClueDetection:
    tuples: Set[Tuple[int, int, int]]
    expected_count: int
    detected_count: int
    uncertain_numbers: List[int]
    strong_numbers: List[int]
    cells: List[Dict[str, Any]]


@dataclass
class SolverStats:
    explored_nodes: int
    dead_states: int
    strategy: str


@dataclass
class SolverResult:
    path: Optional[List[int]]
    stats: SolverStats


@dataclass
class LevelVerification:
    level_id: str
    grid_size: Dict[str, int]
    image_file: str
    clues_ok: bool
    clue_missing: List[Tuple[int, int, int]]
    clue_extra: List[Tuple[int, int, int]]
    clue_uncertain_numbers: List[int]
    walls_ok: bool
    walls_missing: List[Edge]
    walls_extra: List[Edge]
    solver_status: str
    solver_path: List[Coord]
    solver_explored_nodes: int
    solver_dead_states: int
    solver_strategy: str
    attempts_count: int
    duration_ms: int
    repaired: bool
    failure_reason: Optional[str] = None

    @property
    def passed(self) -> bool:
        return self.solver_status == "SOLVED" and self.failure_reason is None

    def to_json(self) -> Dict[str, Any]:
        return {
            "level_id": self.level_id,
            "grid_size": self.grid_size,
            "image_file": self.image_file,
            "attempts_count": self.attempts_count,
            "repaired": self.repaired,
            "clue_comparison": {
                "ok": self.clues_ok,
                "missing": [list(v) for v in self.clue_missing],
                "extra": [list(v) for v in self.clue_extra],
                "uncertain_numbers": self.clue_uncertain_numbers,
            },
            "wall_comparison": {
                "ok": self.walls_ok,
                "missing": [list(v) for v in self.walls_missing],
                "extra": [list(v) for v in self.walls_extra],
            },
            "solver": {
                "status": self.solver_status,
                "path": [list(v) for v in self.solver_path],
                "stats": {
                    "explored_nodes": self.solver_explored_nodes,
                    "dead_states": self.solver_dead_states,
                    "strategy": self.solver_strategy,
                },
            },
            "duration_ms": self.duration_ms,
            "failure_reason": self.failure_reason,
            "passed": self.passed,
        }


# Canonical wall convention:
# walls.h[x,y] blocks (x,y) <-> (x+1,y)
# walls.v[x,y] blocks (x,y) <-> (x,y+1)
def canonical_edge(a: int, b: int) -> Edge:
    return (a, b) if a < b else (b, a)


def cell_to_xy(cell: int, width: int) -> Coord:
    return (cell % width, cell // width)


def xy_to_cell(x: int, y: int, width: int) -> int:
    return y * width + x


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


def wall_coord_to_edge(axis: str, x: int, y: int, width: int, height: int) -> Edge:
    axis = axis.lower()
    if axis == "h":
        if not (0 <= x < width - 1 and 0 <= y < height):
            raise ValueError(f"Horizontal wall out of bounds: {(x, y)}")
        return canonical_edge(xy_to_cell(x, y, width), xy_to_cell(x + 1, y, width))
    if axis == "v":
        if not (0 <= x < width and 0 <= y < height - 1):
            raise ValueError(f"Vertical wall out of bounds: {(x, y)}")
        return canonical_edge(xy_to_cell(x, y, width), xy_to_cell(x, y + 1, width))
    raise ValueError(f"Unknown wall axis: {axis}")


def edge_to_wall_coord(edge: Edge, width: int, height: int) -> WallCoord:
    a, b = canonical_edge(edge[0], edge[1])
    if not is_edge_valid((a, b), width, height):
        raise ValueError(f"Invalid wall edge: {edge}")
    if b - a == 1:
        x, y = cell_to_xy(a, width)
        return ("h", x, y)
    x, y = cell_to_xy(a, width)
    return ("v", x, y)


def edge_set_to_wall_dict(edges: Set[Edge], width: int, height: int) -> Dict[str, List[Dict[str, int]]]:
    h: List[Dict[str, int]] = []
    v: List[Dict[str, int]] = []
    for edge in sorted(edges):
        axis, x, y = edge_to_wall_coord(edge, width, height)
        if axis == "h":
            h.append({"x": x, "y": y})
        else:
            v.append({"x": x, "y": y})
    return {"h": h, "v": v}


def parse_levels_file(path: Path) -> List[Dict[str, Any]]:
    text = path.read_text(encoding="utf-8")
    stripped = text.lstrip()
    if not stripped:
        raise ValueError(f"Levels file is empty: {path}")
    if stripped.startswith("{") or stripped.startswith("["):
        data = json.loads(text)
        if isinstance(data, dict) and isinstance(data.get("levels"), list):
            return [dict(v) for v in data["levels"]]
        if isinstance(data, list):
            return [dict(v) for v in data]
        if isinstance(data, dict):
            return [data]
        raise ValueError("Unsupported JSON shape")
    dec = json.JSONDecoder()
    idx = 0
    out: List[Dict[str, Any]] = []
    while idx < len(text):
        while idx < len(text) and text[idx].isspace():
            idx += 1
        if idx >= len(text):
            break
        obj, idx = dec.raw_decode(text, idx)
        if not isinstance(obj, dict):
            raise ValueError("Concatenated JSON contains non-object")
        out.append(obj)
    return out


def _parse_level_size(raw: Dict[str, Any]) -> Tuple[int, int]:
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
    raise ValueError(f"Level {raw.get('id')} has no size")


def _parse_level_clues(raw: Dict[str, Any], width: int, height: int) -> Dict[int, Coord]:
    clues = raw.get("clues")
    if isinstance(clues, list):
        out: Dict[int, Coord] = {}
        for c in clues:
            if isinstance(c, dict) and "n" in c:
                n = int(c["n"])
                x = int(c.get("x", c.get("col", -1)))
                y = int(c.get("y", c.get("row", -1)))
                if 0 <= x < width and 0 <= y < height:
                    out[n] = (x, y)
        if out:
            return out
    numbers = raw.get("numbers")
    if isinstance(numbers, dict):
        out = {}
        for ck, nv in numbers.items():
            c = int(ck)
            n = int(nv)
            x, y = cell_to_xy(c, width)
            if 0 <= x < width and 0 <= y < height:
                out[n] = (x, y)
        if out:
            return out
    return {}


def _walls_from_hv_dict(walls_obj: Dict[str, Any], width: int, height: int) -> Set[Edge]:
    out: Set[Edge] = set()
    for wh in walls_obj.get("h", walls_obj.get("horizontal", [])) or []:
        if isinstance(wh, dict):
            out.add(wall_coord_to_edge("h", int(wh["x"]), int(wh["y"]), width, height))
    for wv in walls_obj.get("v", walls_obj.get("vertical", [])) or []:
        if isinstance(wv, dict):
            out.add(wall_coord_to_edge("v", int(wv["x"]), int(wv["y"]), width, height))
    return {e for e in out if is_edge_valid(e, width, height)}


def _walls_from_cell_list(walls_list: Iterable[Dict[str, Any]]) -> Set[Edge]:
    out: Set[Edge] = set()
    for w in walls_list:
        if not isinstance(w, dict):
            continue
        c1 = w.get("cell1", w.get("a"))
        c2 = w.get("cell2", w.get("b"))
        if c1 is None or c2 is None:
            continue
        out.add(canonical_edge(int(c1), int(c2)))
    return out


def _walls_from_xy_dir(walls_list: Iterable[Dict[str, Any]], width: int, height: int) -> Set[Edge]:
    out: Set[Edge] = set()
    for w in walls_list:
        if not isinstance(w, dict):
            continue
        if "x" not in w or "y" not in w or "dir" not in w:
            continue
        x = int(w["x"])
        y = int(w["y"])
        d = str(w["dir"]).upper()
        if d in ("E", "R", "RIGHT", "H") and 0 <= x < width - 1 and 0 <= y < height:
            out.add(wall_coord_to_edge("h", x, y, width, height))
        elif d in ("S", "D", "DOWN", "V") and 0 <= x < width and 0 <= y < height - 1:
            out.add(wall_coord_to_edge("v", x, y, width, height))
    return out


def _parse_level_walls(raw: Dict[str, Any], width: int, height: int) -> Set[Edge]:
    walls = raw.get("walls")
    if walls is None:
        return set()
    if isinstance(walls, dict):
        return _walls_from_hv_dict(walls, width, height)
    if isinstance(walls, list):
        if not walls:
            return set()
        sample = walls[0]
        if isinstance(sample, dict) and ("cell1" in sample or "a" in sample):
            return {e for e in _walls_from_cell_list(walls) if is_edge_valid(e, width, height)}
        if isinstance(sample, dict) and "x" in sample and "y" in sample and "dir" in sample:
            return _walls_from_xy_dir(walls, width, height)
    raise ValueError(f"Unsupported walls format for level {raw.get('id')}")


def normalize_levels(records: Sequence[Dict[str, Any]]) -> List[LevelDef]:
    out: List[LevelDef] = []
    for i, raw in enumerate(records, start=1):
        w, h = _parse_level_size(raw)
        clues = _parse_level_clues(raw, w, h)
        walls = _parse_level_walls(raw, w, h)
        level_id = str(raw.get("id") or f"level-{i:03d}")
        image_hint = raw.get("imageFile")
        out.append(
            LevelDef(
                id=level_id,
                width=w,
                height=h,
                clues=clues,
                walls=walls,
                image_hint=str(image_hint) if image_hint else None,
                raw=dict(raw),
            )
        )
    return out


def _parse_numeric_suffix(level_id: str) -> Optional[int]:
    m = re.search(r"(\d+)$", level_id)
    return int(m.group(1)) if m else None


def load_manifest_map(path: Optional[Path]) -> Dict[str, str]:
    if path is None or not path.exists():
        return {}
    data = json.loads(path.read_text(encoding="utf-8"))
    out: Dict[str, str] = {}
    items = data.get("images") if isinstance(data, dict) else None
    for item in items or []:
        if isinstance(item, dict):
            lid = item.get("matchedLevelId") or item.get("levelId")
            file_name = item.get("file") or item.get("filename")
            if lid and file_name:
                out[str(lid)] = str(file_name)
    return out


def autodiscover_manifest(levels_json_path: Path) -> Optional[Path]:
    matches = sorted(levels_json_path.parent.glob("*image_manifest*.json"))
    return matches[0] if matches else None


_IMAGE_INDEX_CACHE: Dict[Tuple[str, Tuple[str, ...]], Dict[str, List[Path]]] = {}
_OCR_DARK_CACHE: Dict[bytes, Dict[int, int]] = {}
_OCR_LIGHT_CACHE: Dict[bytes, Dict[int, int]] = {}


def _build_image_index(images_dir: Path, ignored_dirs: Sequence[str]) -> Dict[str, List[Path]]:
    cache_key = (str(images_dir.resolve()), tuple(sorted(d.lower() for d in ignored_dirs)))
    if cache_key in _IMAGE_INDEX_CACHE:
        return _IMAGE_INDEX_CACHE[cache_key]
    ignored = {d.lower() for d in ignored_dirs}
    by_key: Dict[str, List[Path]] = {}
    for root, dirs, files in os.walk(images_dir):
        dirs[:] = [d for d in dirs if d.lower() not in ignored]
        for name in files:
            low = name.lower()
            if not (low.endswith(".png") or low.endswith(".jpg") or low.endswith(".jpeg")):
                continue
            p = Path(root) / name
            for key in {low, Path(name).stem.lower()}:
                by_key.setdefault(key, []).append(p)
    for key in list(by_key.keys()):
        by_key[key] = sorted(by_key[key], key=lambda p: str(p).lower())
    _IMAGE_INDEX_CACHE[cache_key] = by_key
    return by_key


def _first_index_match(index: Dict[str, List[Path]], key: str) -> Optional[Path]:
    vals = index.get(key.lower())
    return vals[0] if vals else None


def resolve_image_for_level(
    level: LevelDef,
    images_dir: Path,
    manifest_map: Dict[str, str],
    ignored_dirs: Sequence[str] = ("dbg", "debug", "out", "out old", "qa"),
) -> Optional[Path]:
    idx = _build_image_index(images_dir, ignored_dirs)
    if level.image_hint:
        p = images_dir / level.image_hint
        if p.exists():
            return p
        hit = _first_index_match(idx, level.image_hint)
        if hit is not None:
            return hit
    mapped = manifest_map.get(level.id)
    if mapped:
        p = images_dir / mapped
        if p.exists():
            return p
        hit = _first_index_match(idx, mapped)
        if hit is not None:
            return hit
    num = _parse_numeric_suffix(level.id)
    if num is not None:
        for name in (f"{num}.png", f"{num}.jpg", f"{num}.jpeg"):
            p = images_dir / name
            if p.exists():
                return p
            hit = _first_index_match(idx, name)
            if hit is not None:
                return hit
        stem_hit = _first_index_match(idx, str(num))
        if stem_hit is not None:
            return stem_hit
    return None


def _board_bbox(gray: np.ndarray) -> Tuple[int, int, int, int]:
    h, w = gray.shape
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    edges = cv2.Canny(blur, 40, 130)
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    best: Optional[Tuple[float, Tuple[int, int, int, int]]] = None
    for c in contours:
        x, y, cw, ch = cv2.boundingRect(c)
        if cw < 0.45 * w or ch < 0.45 * h:
            continue
        area = float(cw * ch)
        aspect = cw / max(1.0, ch)
        score = area / max(1.0, w * h) - 0.25 * abs(aspect - 1.0)
        if best is None or score > best[0]:
            best = (score, (x, y, x + cw, y + ch))
    if best is None:
        m = int(min(w, h) * 0.04)
        return (m, m, w - m, h - m)
    x0, y0, x1, y1 = best[1]
    bw = max(1, x1 - x0)
    bh = max(1, y1 - y0)
    fill = float(bw * bh) / float(max(1, w * h))
    aspect = float(bw) / float(max(1, bh))
    if fill < 0.55 or ((aspect < 0.8 or aspect > 1.2) and fill < 0.75):
        m = int(min(w, h) * 0.04)
        return (m, m, w - m, h - m)
    p = int(min(w, h) * 0.02)
    return (max(0, x0 - p), max(0, y0 - p), min(w, x1 + p), min(h, y1 + p))


def _cluster_projection_peaks(signal: np.ndarray, threshold: float = 0.30) -> List[int]:
    s = signal.astype(np.float64)
    if s.size == 0 or float(np.max(s)) <= float(np.min(s)) + 1e-9:
        return []
    norm = (s - np.min(s)) / (np.max(s) - np.min(s))
    idx = np.where(norm > threshold)[0]
    if idx.size == 0:
        return []
    peaks: List[int] = []
    i = 0
    while i < len(idx):
        j = i
        while j + 1 < len(idx) and idx[j + 1] - idx[j] <= 1:
            j += 1
        seg = idx[i : j + 1]
        peaks.append(int(seg[int(np.argmax(norm[seg]))]))
        i = j + 1
    return peaks


def _limit_peaks(peaks: Sequence[int], signal: np.ndarray, max_count: int = 16) -> List[int]:
    if len(peaks) <= max_count:
        return list(peaks)
    strongest = sorted(peaks, key=lambda p: float(signal[p]), reverse=True)[:max_count]
    return sorted(strongest)


def _best_equal_spacing_subset(
    peaks: Sequence[int],
    target_count: int,
    signal: np.ndarray,
) -> Optional[Tuple[List[int], float]]:
    if len(peaks) < target_count:
        return None
    if len(peaks) == target_count:
        vals = np.array(peaks, dtype=np.float64)
        dif = np.diff(vals)
        return None if dif.size == 0 else (list(map(int, peaks)), float(np.var(dif)))
    best: Optional[Tuple[float, List[int]]] = None
    for comb in combinations(peaks, target_count):
        vals = np.array(comb, dtype=np.float64)
        dif = np.diff(vals)
        if dif.size == 0:
            continue
        mean = float(np.mean(dif))
        if mean <= 5.0:
            continue
        var = float(np.var(dif))
        jitter = float(np.mean(np.abs(vals - np.linspace(vals[0], vals[-1], target_count))))
        support = float(np.mean(signal[list(comb)]))
        score = var + 0.6 * jitter - 0.001 * support
        if best is None or score < best[0]:
            best = (score, list(map(int, vals)))
    return None if best is None else (best[1], best[0])


def _detect_grid_for_dims(gray: np.ndarray, width: int, height: int) -> GridDetection:
    x0, y0, x1, y1 = _board_bbox(gray)
    roi = gray[y0:y1, x0:x1]
    dark = (roi < 192).astype(np.uint8)
    col = dark.sum(axis=0)
    row = dark.sum(axis=1)
    x_peaks = _limit_peaks(_cluster_projection_peaks(col), col)
    y_peaks = _limit_peaks(_cluster_projection_peaks(row), row)
    x_fit = _best_equal_spacing_subset(x_peaks, width + 1, col)
    y_fit = _best_equal_spacing_subset(y_peaks, height + 1, row)
    if x_fit is None or y_fit is None:
        raise RuntimeError(f"Could not detect grid lines for {width}x{height}")
    xs, sx = x_fit
    ys, sy = y_fit
    count_penalty = 0.65 * abs(len(x_peaks) - (width + 1)) + 0.65 * abs(len(y_peaks) - (height + 1))
    return GridDetection(
        bbox=(x0, y0, x1, y1),
        x_lines=[x0 + v for v in xs],
        y_lines=[y0 + v for v in ys],
        score=float((sx or 0.0) + (sy or 0.0) + count_penalty),
    )


def _optimize_periodic_lines(signal: np.ndarray, count: int) -> Optional[Tuple[List[int], float]]:
    length = int(signal.shape[0])
    if count < 2 or length < count + 2:
        return None
    # Search an equally-spaced line family. This catches faint full-grid lines
    # when peak clustering fails (notably white-circle screenshots).
    step_lo = max(6.0, length / (count + 1.5))
    step_hi = max(step_lo + 1.0, length / max(2.0, count - 0.5))
    best: Optional[Tuple[float, List[int]]] = None
    steps = np.linspace(step_lo, step_hi, 220)
    for step in steps:
        span = step * (count - 1)
        start_max = max(1.0, (length - 1.0) - span)
        starts = np.linspace(0.0, start_max, 100)
        for start in starts:
            idx = np.round(start + np.arange(count) * step).astype(int)
            idx = np.clip(idx, 0, length - 1)
            vals = signal[idx]
            spacing = np.diff(idx.astype(np.float64))
            var = float(np.var(spacing)) if spacing.size else 0.0
            score = float(np.sum(vals) - 0.35 * var)
            if best is None or score > best[0]:
                best = (score, [int(v) for v in idx])
    if best is None:
        return None
    return best[1], -best[0]


def _detect_grid_for_dims_periodic(gray: np.ndarray, width: int, height: int) -> GridDetection:
    x0, y0, x1, y1 = _board_bbox(gray)
    roi = gray[y0:y1, x0:x1]
    if roi.size == 0:
        raise RuntimeError("Empty board ROI")
    gx = np.abs(cv2.Sobel(roi, cv2.CV_32F, 1, 0, ksize=3))
    gy = np.abs(cv2.Sobel(roi, cv2.CV_32F, 0, 1, ksize=3))
    col = np.sum(gx, axis=0)
    row = np.sum(gy, axis=1)
    x_fit = _optimize_periodic_lines(col, width + 1)
    y_fit = _optimize_periodic_lines(row, height + 1)
    if x_fit is None or y_fit is None:
        raise RuntimeError(f"Could not detect periodic grid lines for {width}x{height}")
    xs, sx = x_fit
    ys, sy = y_fit
    # Prefer square-ish cell geometry when periodic scores are close.
    cell_w = (xs[-1] - xs[0]) / max(1.0, float(width))
    cell_h = (ys[-1] - ys[0]) / max(1.0, float(height))
    geom_penalty = 0.45 * abs(cell_w - cell_h)
    sx_norm = float(sx) / max(1.0, float(np.sum(col)))
    sy_norm = float(sy) / max(1.0, float(np.sum(row)))
    return GridDetection(
        bbox=(x0, y0, x1, y1),
        x_lines=[x0 + v for v in xs],
        y_lines=[y0 + v for v in ys],
        score=float((sx_norm or 0.0) + (sy_norm or 0.0) + geom_penalty + 2.0),
    )


def detect_grid(gray: np.ndarray, width: int, height: int) -> GridDetection:
    return _detect_grid_for_dims(gray, width, height)


def detect_grid_size_from_image(
    gray: np.ndarray,
    preferred_size: Optional[Tuple[int, int]] = None,
    min_size: int = 5,
    max_size: int = 9,
) -> GridDetection:
    candidates: List[Tuple[int, int]] = []
    if preferred_size:
        pw, ph = preferred_size
        for dw in (0, -1, 1):
            for dh in (0, -1, 1):
                w, h = pw + dw, ph + dh
                if min_size <= w <= max_size and min_size <= h <= max_size:
                    candidates.append((w, h))
    for w in range(min_size, max_size + 1):
        for h in range(min_size, max_size + 1):
            candidates.append((w, h))
    seen: Set[Tuple[int, int]] = set()
    best: Optional[GridDetection] = None
    best_score = float("inf")
    for w, h in candidates:
        if (w, h) in seen:
            continue
        seen.add((w, h))
        grids: List[GridDetection] = []
        try:
            grids.append(_detect_grid_for_dims(gray, w, h))
        except Exception:
            pass
        try:
            grids.append(_detect_grid_for_dims_periodic(gray, w, h))
        except Exception:
            pass
        for grid in grids:
            candidate_score = float(grid.score)
            if preferred_size is not None:
                pw, ph = preferred_size
                candidate_score += 1000.0 * (abs(w - pw) + abs(h - ph))
            if best is None or candidate_score < best_score:
                best = grid
                best_score = candidate_score
    if best is None:
        raise RuntimeError("Could not detect grid size from image")
    return best


def fallback_grid_from_bbox(gray: np.ndarray, width: int, height: int) -> GridDetection:
    x0, y0, x1, y1 = _board_bbox(gray)
    x_lines = [int(round(x0 + (x1 - x0) * (i / width))) for i in range(width + 1)]
    y_lines = [int(round(y0 + (y1 - y0) * (i / height))) for i in range(height + 1)]
    return GridDetection(bbox=(x0, y0, x1, y1), x_lines=x_lines, y_lines=y_lines, score=9999.0)


def pixel_to_cell(x: int, y: int, grid: GridDetection) -> Optional[Coord]:
    gx = gy = -1
    for i in range(len(grid.x_lines) - 1):
        if grid.x_lines[i] <= x <= grid.x_lines[i + 1]:
            gx = i
            break
    for j in range(len(grid.y_lines) - 1):
        if grid.y_lines[j] <= y <= grid.y_lines[j + 1]:
            gy = j
            break
    return None if gx < 0 or gy < 0 else (gx, gy)


def _ocr_votes_for_cell_patch(patch_gray: np.ndarray) -> Dict[int, int]:
    h, w = patch_gray.shape
    if h < 8 or w < 8:
        return {}
    key = hashlib.sha1(patch_gray.tobytes()).digest()
    cached = _OCR_DARK_CACHE.get(key)
    if cached is not None:
        return dict(cached)
    mask = np.zeros_like(patch_gray)
    cv2.circle(mask, (w // 2, h // 2), int(min(w, h) * 0.40), 255, -1)
    inside = cv2.bitwise_and(patch_gray, patch_gray, mask=mask)
    up = cv2.resize(255 - cv2.GaussianBlur(inside, (3, 3), 0), None, fx=5, fy=5, interpolation=cv2.INTER_CUBIC)
    variants = [
        cv2.threshold(up, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1],
        cv2.threshold(up, 175, 255, cv2.THRESH_BINARY)[1],
    ]
    votes: Dict[int, int] = {}
    for variant in variants:
        for psm in (10, 13):
            try:
                txt = pytesseract.image_to_string(
                    variant,
                    config=f"--psm {psm} -c tessedit_char_whitelist=0123456789",
                )
            except Exception:
                _OCR_DARK_CACHE[key] = dict(votes)
                return dict(votes)
            digits = "".join(ch for ch in txt if ch.isdigit())
            if not digits:
                continue
            n = int(digits[:2])
            votes[n] = votes.get(n, 0) + 1
    _OCR_DARK_CACHE[key] = dict(votes)
    return dict(votes)


def _ocr_votes_for_light_cell_patch(patch_gray: np.ndarray) -> Dict[int, int]:
    h, w = patch_gray.shape
    if h < 8 or w < 8:
        return {}
    key = hashlib.sha1(patch_gray.tobytes()).digest()
    cached = _OCR_LIGHT_CACHE.get(key)
    if cached is not None:
        return dict(cached)
    center_span = int(min(h, w) * 0.52)
    y0 = max(0, (h - center_span) // 2)
    x0 = max(0, (w - center_span) // 2)
    center = patch_gray[y0 : y0 + center_span, x0 : x0 + center_span]
    up = cv2.resize(center, None, fx=10, fy=10, interpolation=cv2.INTER_CUBIC)
    up = cv2.GaussianBlur(up, (3, 3), 0)
    variants = [
        cv2.adaptiveThreshold(up, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 31, 7),
        cv2.threshold(up, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1],
    ]
    variants.append(255 - variants[-1])
    votes: Dict[int, int] = {}
    for variant in variants:
        for psm in (8, 10):
            try:
                txt = pytesseract.image_to_string(
                    variant,
                    config=f"--psm {psm} --oem 1 -c tessedit_char_whitelist=0123456789",
                )
            except Exception:
                _OCR_LIGHT_CACHE[key] = dict(votes)
                return dict(votes)
            digits = "".join(ch for ch in txt if ch.isdigit())
            if not digits:
                continue
            n = int(digits[:2])
            votes[n] = votes.get(n, 0) + 1
    _OCR_LIGHT_CACHE[key] = dict(votes)
    return dict(votes)


def _circle_style_scores(patch_gray: np.ndarray) -> Tuple[float, float, float]:
    h, w = patch_gray.shape
    if h < 8 or w < 8:
        return 0.0, 0.0, 0.0
    yy, xx = np.ogrid[:h, :w]
    d = np.sqrt((xx - (w / 2.0)) ** 2 + (yy - (h / 2.0)) ** 2)
    r = 0.5 * min(h, w)
    inner_black = d <= (r * 0.56)
    ring = (d >= (r * 0.74)) & (d <= (r * 0.93))
    inner_bright = d <= (r * 0.56)
    black_dark = float((patch_gray[inner_black] < 80).mean()) if np.any(inner_black) else 0.0
    ring_dark = float((patch_gray[ring] < 180).mean()) if np.any(ring) else 0.0
    bright = float((patch_gray[inner_bright] > 182).mean()) if np.any(inner_bright) else 0.0
    return black_dark, ring_dark, bright


def detect_clues(
    bgr: np.ndarray,
    gray: np.ndarray,
    grid: GridDetection,
    expected_numbers: Sequence[int],
    prior_clues: Optional[Dict[int, Coord]] = None,
    variant: int = 0,
) -> ClueDetection:
    expected = sorted(set(int(v) for v in expected_numbers))
    prior_clues = prior_clues or {}
    min_dark = [0.30, 0.27, 0.33, 0.26, 0.35][variant % 5]
    min_ring = [0.07, 0.06, 0.08, 0.05, 0.09][variant % 5]
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    cands: List[Dict[str, Any]] = []
    for y in range(grid.height):
        for x in range(grid.width):
            cx = (grid.x_lines[x] + grid.x_lines[x + 1]) // 2
            cy = (grid.y_lines[y] + grid.y_lines[y + 1]) // 2
            r = int(
                0.46
                * min(
                    grid.x_lines[x + 1] - grid.x_lines[x],
                    grid.y_lines[y + 1] - grid.y_lines[y],
                )
            )
            patch = gray[
                max(0, cy - r) : min(gray.shape[0], cy + r),
                max(0, cx - r) : min(gray.shape[1], cx + r),
            ]
            if patch.size == 0:
                continue
            black_dark, ring_dark, bright = _circle_style_scores(patch)
            style = "dark" if black_dark >= min_dark else ("light" if (ring_dark >= min_ring and bright >= 0.82) else None)
            if style is None:
                continue
            sat = float(
                np.mean(
                    hsv[
                        grid.y_lines[y] : grid.y_lines[y + 1],
                        grid.x_lines[x] : grid.x_lines[x + 1],
                        1,
                    ]
                )
            )
            clue_score = black_dark if style == "dark" else (0.55 * ring_dark + 0.45 * bright)
            px0 = max(0, cy - r)
            px1 = min(gray.shape[0], cy + r)
            py0 = max(0, cx - r)
            py1 = min(gray.shape[1], cx + r)
            cands.append(
                {
                    "x": x,
                    "y": y,
                    "center": (cx, cy),
                    "dark": black_dark,
                    "ring_dark": ring_dark,
                    "bright": bright,
                    "style": style,
                    "sat": sat,
                    "votes": {},
                    "bbox": (px0, px1, py0, py1),
                    "base_score": clue_score + 0.0008 * sat,
                    "score": clue_score + 0.0008 * sat,
                }
            )
    if not cands:
        return ClueDetection(
            tuples=set(),
            expected_count=len(expected),
            detected_count=0,
            uncertain_numbers=expected,
            strong_numbers=[],
            cells=[],
        )
    cands.sort(key=lambda c: (-c["base_score"], c["y"], c["x"]))
    if expected:
        cands = cands[: min(len(cands), max(len(expected) * 2, len(expected) + 4))]
    else:
        cands = cands[: min(len(cands), max(10, (grid.width * grid.height) // 3))]

    for c in cands:
        y0, y1, x0, x1 = c["bbox"]
        patch = gray[y0:y1, x0:x1]
        votes = _ocr_votes_for_cell_patch(patch) if c.get("style") == "dark" else _ocr_votes_for_light_cell_patch(patch)
        c["votes"] = votes
        c["score"] = c["base_score"] + 0.02 * (max(votes.values()) if votes else 0.0)

    tuples: Set[Tuple[int, int, int]] = set()
    uncertain: List[int] = []
    strong: List[int] = []
    if expected:
        cols = max(len(expected), len(cands))
        # Pad with dummy columns so we can mark missing clues cleanly.
        cost = np.full((len(expected), cols), 8.0, dtype=np.float64)
        for i, n in enumerate(expected):
            px, py = prior_clues.get(n, (-1, -1))
            for j, c in enumerate(cands):
                vote = float(c["votes"].get(n, 0))
                best_vote = float(max(c["votes"].values())) if c["votes"] else 0.0
                dist = 0.0 if px < 0 else 0.85 * (abs(px - c["x"]) + abs(py - c["y"]))
                style_pen = 0.0 if c.get("style") == "dark" else 0.22
                weak_vote_pen = 0.9 if vote <= 0 else 0.0
                cost[i, j] = (
                    dist
                    - 2.6 * vote
                    - 1.2 * c["score"]
                    + 0.28 * max(0.0, best_vote - vote)
                    + style_pen
                    + weak_vote_pen
                )
        rr, cc = linear_sum_assignment(cost)
        for r, cidx in zip(rr, cc):
            n = expected[int(r)]
            if int(cidx) >= len(cands):
                uncertain.append(n)
                continue
            c = cands[int(cidx)]
            vote = int(c["votes"].get(n, 0))
            tuples.add((n, int(c["x"]), int(c["y"])))
            c["assigned_n"] = n
            c["assigned_score"] = vote
            prior = prior_clues.get(n)
            close = prior is not None and abs(prior[0] - c["x"]) + abs(prior[1] - c["y"]) <= 1
            if vote > 0 or close:
                strong.append(n)
            if vote <= 0 and not close:
                uncertain.append(n)
        uncertain.extend(sorted(set(expected) - {n for n, _, _ in tuples}))
    else:
        for c in cands:
            if c["votes"]:
                n = max(c["votes"].items(), key=lambda kv: (kv[1], -kv[0]))[0]
                tuples.add((int(n), int(c["x"]), int(c["y"])))
                c["assigned_n"] = int(n)
                c["assigned_score"] = int(c["votes"][n])

    return ClueDetection(
        tuples=tuples,
        expected_count=len(expected),
        detected_count=len(cands),
        uncertain_numbers=sorted(set(uncertain)),
        strong_numbers=sorted(set(strong)),
        cells=cands,
    )


def detect_walls(gray: np.ndarray, grid: GridDetection, variant: int = 0) -> Set[Edge]:
    w, h = grid.width, grid.height
    board = gray[grid.bbox[1] : grid.bbox[3], grid.bbox[0] : grid.bbox[2]]
    dark_thr = int(np.clip(np.percentile(board, 18), 42, 132))
    ratio_thr = [0.44, 0.38, 0.50, 0.34, 0.56][variant % 5]
    walls: Set[Edge] = set()

    for y in range(h):
        yt, yb = grid.y_lines[y], grid.y_lines[y + 1]
        cell_h = yb - yt
        for x in range(w - 1):
            lx = grid.x_lines[x + 1]
            sh = max(6, int(cell_h * 0.68))
            sw = max(
                6,
                int(
                    min(
                        grid.x_lines[x + 1] - grid.x_lines[x],
                        grid.x_lines[x + 2] - grid.x_lines[x + 1],
                    )
                    * 0.12
                ),
            )
            cy = (yt + yb) // 2
            patch = gray[
                max(0, cy - sh // 2) : min(gray.shape[0], cy + sh // 2),
                max(0, lx - sw // 2) : min(gray.shape[1], lx + sw // 2),
            ]
            if patch.size and float((patch < dark_thr).mean()) >= ratio_thr:
                walls.add(canonical_edge(xy_to_cell(x, y, w), xy_to_cell(x + 1, y, w)))

    for y in range(h - 1):
        ly = grid.y_lines[y + 1]
        for x in range(w):
            xl, xr = grid.x_lines[x], grid.x_lines[x + 1]
            cell_w = xr - xl
            sw = max(6, int(cell_w * 0.68))
            sh = max(
                6,
                int(
                    min(
                        grid.y_lines[y + 1] - grid.y_lines[y],
                        grid.y_lines[y + 2] - grid.y_lines[y + 1],
                    )
                    * 0.12
                ),
            )
            cx = (xl + xr) // 2
            patch = gray[
                max(0, ly - sh // 2) : min(gray.shape[0], ly + sh // 2),
                max(0, cx - sw // 2) : min(gray.shape[1], cx + sw // 2),
            ]
            if patch.size and float((patch < dark_thr).mean()) >= ratio_thr:
                walls.add(canonical_edge(xy_to_cell(x, y, w), xy_to_cell(x, y + 1, w)))
    return walls


def _build_adjacency(width: int, height: int, walls: Set[Edge]) -> List[List[int]]:
    total = width * height
    adj: List[List[int]] = [[] for _ in range(total)]
    for c in range(total):
        x, y = cell_to_xy(c, width)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                n = xy_to_cell(nx, ny, width)
                if canonical_edge(c, n) not in walls:
                    adj[c].append(n)
    for row in adj:
        row.sort()
    return adj


def solve_level(level: LevelDef, strategy: str = "clue_degree") -> Optional[List[int]]:
    return solve_level_with_stats(level, strategy=strategy).path


def solve_level_with_stats(level: LevelDef, strategy: str = "clue_degree") -> SolverResult:
    if not level.clues:
        return SolverResult(None, SolverStats(0, 0, strategy))
    numbers = sorted(level.clues)
    if numbers != list(range(1, numbers[-1] + 1)):
        return SolverResult(None, SolverStats(0, 0, strategy))

    w, h = level.width, level.height
    total = w * h
    for edge in level.walls:
        if not is_edge_valid(edge, w, h):
            return SolverResult(None, SolverStats(0, 0, strategy))

    start = xy_to_cell(*level.clues[1], w)
    end = xy_to_cell(*level.clues[numbers[-1]], w)
    clue_by_cell: Dict[int, int] = {}
    clue_cell_by_num: Dict[int, int] = {}
    for n, (x, y) in level.clues.items():
        if not (0 <= x < w and 0 <= y < h):
            return SolverResult(None, SolverStats(0, 0, strategy))
        c = xy_to_cell(x, y, w)
        if c in clue_by_cell and clue_by_cell[c] != n:
            return SolverResult(None, SolverStats(0, 0, strategy))
        clue_by_cell[c] = n
        clue_cell_by_num[n] = c

    adj = _build_adjacency(w, h, level.walls)
    path: List[int] = [start]
    dead: Set[Tuple[int, int, int]] = set()
    explored = 0
    dead_hits = 0
    node_limit = 220000 if total >= 42 else 120000
    aborted = False

    def parity_prune(cur: int) -> bool:
        left = total - len(path)
        cx, cy = cell_to_xy(cur, w)
        ex, ey = cell_to_xy(end, w)
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
        if expected <= numbers[-1] and ((mask >> clue_cell_by_num[expected]) & 1):
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
        if expected > numbers[-1]:
            return False
        target = clue_cell_by_num[expected]
        if (mask >> target) & 1:
            return True
        q = [cur]
        seen = {cur}
        i = 0
        while i < len(q):
            node = q[i]
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
                q.append(nb)
        return True

    def degree(cell: int, next_mask: int) -> int:
        return sum(1 for nb in adj[cell] if ((next_mask >> nb) & 1) == 0)

    def sort_key(row: Tuple[int, int, int, int]) -> Tuple[int, int, int, int]:
        clue_rank, deg, dist, nb = row
        if strategy == "degree_clue":
            return (deg, clue_rank, dist, nb)
        if strategy == "end_distance":
            return (clue_rank, dist, deg, nb)
        if strategy == "reverse_degree":
            return (clue_rank, -deg, dist, nb)
        if strategy == "reverse_end":
            return (clue_rank, -dist, deg, nb)
        return (clue_rank, deg, dist, nb)

    def dfs(cur: int, mask: int, expected: int) -> bool:
        nonlocal explored, dead_hits, aborted
        if explored >= node_limit:
            aborted = True
            return False
        explored += 1
        state = (cur, mask, expected)
        if state in dead:
            dead_hits += 1
            return False
        if len(path) == total:
            if cur == end and expected == numbers[-1] + 1:
                return True
            dead.add(state)
            return False
        if cur == end:
            dead.add(state)
            return False
        if (
            parity_prune(cur)
            or conn_prune(cur, mask)
            or dead_cell_prune(cur, mask, expected)
            or next_clue_reach_prune(cur, mask, expected)
        ):
            dead.add(state)
            return False

        ex, ey = cell_to_xy(end, w)
        cand: List[Tuple[int, int, int, int]] = []
        for nb in adj[cur]:
            if (mask >> nb) & 1:
                continue
            if nb == end and len(path) != total - 1:
                continue
            cn = clue_by_cell.get(nb)
            if cn is not None and cn != expected:
                continue
            nx, ny = cell_to_xy(nb, w)
            cand.append((0 if cn == expected else 1, degree(nb, mask | (1 << nb)), abs(nx - ex) + abs(ny - ey), nb))
        cand.sort(key=sort_key)
        for _, _, _, nb in cand:
            cn = clue_by_cell.get(nb)
            nxt = expected + 1 if cn == expected else expected
            path.append(nb)
            if dfs(nb, mask | (1 << nb), nxt):
                return True
            path.pop()
            if aborted:
                return False
        dead.add(state)
        return False

    ok = dfs(start, 1 << start, 2)
    return SolverResult(path=list(path) if ok else None, stats=SolverStats(explored, dead_hits, strategy))


def _edge_segment_pixels(edge: Edge, width: int, x_lines: Sequence[int], y_lines: Sequence[int]) -> Tuple[Tuple[int, int], Tuple[int, int]]:
    a, b = canonical_edge(edge[0], edge[1])
    if b - a == 1:
        x, y = cell_to_xy(a, width)
        return (x_lines[x + 1], y_lines[y]), (x_lines[x + 1], y_lines[y + 1])
    x, y = cell_to_xy(a, width)
    return (x_lines[x], y_lines[y + 1]), (x_lines[x + 1], y_lines[y + 1])


def draw_level_artifacts(
    image_path: Path,
    grid: GridDetection,
    level: LevelDef,
    clue_detection: ClueDetection,
    detected_walls: Set[Edge],
    out_annotated: Path,
    out_walls_diff: Path,
) -> None:
    bgr = cv2.imread(str(image_path))
    if bgr is None:
        return
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    img = Image.fromarray(rgb.copy())
    draw = ImageDraw.Draw(img)
    for x in grid.x_lines:
        draw.line([(x, grid.y_lines[0]), (x, grid.y_lines[-1])], fill=(255, 196, 0), width=1)
    for y in grid.y_lines:
        draw.line([(grid.x_lines[0], y), (grid.x_lines[-1], y)], fill=(255, 196, 0), width=1)
    for c in clue_detection.cells:
        cx, cy = c["center"]
        r = int(
            0.28
            * min(
                grid.x_lines[c["x"] + 1] - grid.x_lines[c["x"]],
                grid.y_lines[c["y"] + 1] - grid.y_lines[c["y"]],
            )
        )
        n = c.get("assigned_n")
        score = int(c.get("assigned_score", 0))
        color = (0, 220, 0) if (n is not None and score > 0) else (220, 220, 0)
        draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], outline=color, width=2)
        if n is not None:
            draw.text((cx + r + 2, cy - r - 2), f"{n}@{c['x']},{c['y']}", fill=color)
    img.save(out_annotated)

    diff_img = Image.fromarray(rgb.copy())
    diff = ImageDraw.Draw(diff_img)
    for edge in sorted(level.walls & detected_walls):
        p1, p2 = _edge_segment_pixels(edge, level.width, grid.x_lines, grid.y_lines)
        diff.line([p1, p2], fill=(0, 220, 0), width=4)
    for edge in sorted(detected_walls - level.walls):
        p1, p2 = _edge_segment_pixels(edge, level.width, grid.x_lines, grid.y_lines)
        diff.line([p1, p2], fill=(220, 0, 0), width=4)
    for edge in sorted(level.walls - detected_walls):
        p1, p2 = _edge_segment_pixels(edge, level.width, grid.x_lines, grid.y_lines)
        diff.line([p1, p2], fill=(0, 128, 255), width=4)
    diff_img.save(out_walls_diff)


def draw_solver_path_overlay(image_path: Path, grid: GridDetection, solver_path: Sequence[Coord], out_path: Path) -> None:
    bgr = cv2.imread(str(image_path))
    if bgr is None:
        return
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    img = Image.fromarray(rgb)
    draw = ImageDraw.Draw(img)
    if solver_path:
        pts = [
            ((grid.x_lines[x] + grid.x_lines[x + 1]) // 2, (grid.y_lines[y] + grid.y_lines[y + 1]) // 2)
            for x, y in solver_path
        ]
        if len(pts) >= 2:
            draw.line(pts, fill=(34, 139, 34), width=5)
        for i, (cx, cy) in enumerate(pts):
            draw.ellipse([(cx - 4, cy - 4), (cx + 4, cy + 4)], fill=((0, 70, 220) if i == 0 else (220, 70, 0)))
    img.save(out_path)


def _save_failure_artifacts(image_path: Path, outdir: Path) -> None:
    outdir.mkdir(parents=True, exist_ok=True)
    bgr = cv2.imread(str(image_path))
    if bgr is None:
        return
    rgb = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
    img = Image.fromarray(rgb)
    for name in ("annotated.png", "walls_diff.png", "solver_path.png"):
        img.save(outdir / name)


def _level_signature(level: LevelDef) -> Tuple[Any, ...]:
    return (
        level.width,
        level.height,
        tuple(sorted((n, x, y) for n, (x, y) in level.clues.items())),
        tuple(sorted(level.walls)),
    )


def _resize_level(level: LevelDef, width: int, height: int) -> LevelDef:
    clues = {n: (x, y) for n, (x, y) in level.clues.items() if 0 <= x < width and 0 <= y < height}
    walls = {e for e in level.walls if is_edge_valid(e, width, height)}
    return replace(level, width=width, height=height, clues=clues, walls=walls)


def _clue_tuples_from_level(level: LevelDef) -> Set[Tuple[int, int, int]]:
    return {(int(n), int(x), int(y)) for n, (x, y) in level.clues.items()}


def _clue_map_from_detection(d: ClueDetection, expected: Sequence[int]) -> Dict[int, Coord]:
    keep = set(expected)
    return {n: (x, y) for n, x, y in sorted(d.tuples) if n in keep}


def _apply_single_clue_move(clues: Dict[int, Coord], n: int, target: Coord) -> Dict[int, Coord]:
    out = dict(clues)
    cur = out.get(n)
    occ = next((k for k, v in out.items() if k != n and v == target), None)
    out[n] = target
    if occ is not None and cur is not None:
        out[occ] = cur
    return out


def _repair_clues_stage(level: LevelDef, d: ClueDetection, expected: Sequence[int], attempt: int) -> LevelDef:
    detected = _clue_map_from_detection(d, expected)
    if not detected:
        return level
    clues = dict(level.clues)
    changed = False
    movers = [n for n in sorted(expected) if n in detected and clues.get(n) != detected[n]]
    if movers:
        if attempt % 5 == 0:
            for n in movers:
                if n in d.strong_numbers or n == 1:
                    clues = _apply_single_clue_move(clues, n, detected[n])
                    changed = True
        else:
            n = movers[(attempt // 3) % len(movers)]
            if n in d.strong_numbers or attempt % 4 == 0:
                clues = _apply_single_clue_move(clues, n, detected[n])
                changed = True
    for n in sorted(expected):
        if n not in clues and n in detected:
            clues[n] = detected[n]
            changed = True
    return replace(level, clues=clues) if changed else level


def _repair_walls_add_stage(level: LevelDef, detected: Set[Edge], attempt: int) -> LevelDef:
    if not detected:
        return level
    cur = set(level.walls)
    missing = sorted(detected - cur)
    if not missing:
        return replace(level, walls=set(detected)) if attempt % 11 == 0 else level
    cur.add(missing[(attempt // 3) % len(missing)])
    if attempt % 9 == 0:
        cur |= detected
    return replace(level, walls=cur)


def _repair_walls_remove_stage(level: LevelDef, detected: Set[Edge], attempt: int) -> LevelDef:
    cur = set(level.walls)
    extra = sorted(cur - detected)
    if not extra:
        return replace(level, walls=cur & detected) if (detected and attempt % 13 == 0) else level
    cur.remove(extra[(attempt // 3) % len(extra)])
    if attempt % 10 == 0:
        cur &= detected
    return replace(level, walls=cur)


def _repair_minimal_stage(level: LevelDef, d: ClueDetection, detected_walls: Set[Edge], expected: Sequence[int], attempt: int) -> LevelDef:
    clues = dict(level.clues)
    walls = set(level.walls)
    changed = False
    detected_clues = _clue_map_from_detection(d, expected)
    for n in sorted(expected):
        if n in detected_clues and n in d.strong_numbers and clues.get(n) != detected_clues[n]:
            clues = _apply_single_clue_move(clues, n, detected_clues[n])
            changed = True
    add = sorted(detected_walls - walls)
    rm = sorted(walls - detected_walls)
    if add and attempt % 2 == 0:
        walls.add(add[(attempt // 2) % len(add)])
        changed = True
    if rm and attempt % 2 == 1:
        walls.remove(rm[(attempt // 2) % len(rm)])
        changed = True
    if detected_walls and attempt % 17 == 0:
        walls = set(detected_walls)
        changed = True
    return replace(level, clues=clues, walls=walls) if changed else level


def _solver_strategies() -> List[str]:
    return ["clue_degree", "degree_clue", "end_distance", "reverse_degree", "reverse_end"]


def _solution_payload(level: LevelDef, path_xy: Sequence[Coord]) -> Dict[str, Any]:
    return {
        "id": level.id,
        "size": {"w": level.width, "h": level.height},
        "clues": [{"n": int(n), "x": int(x), "y": int(y)} for n, (x, y) in sorted(level.clues.items())],
        "walls": edge_set_to_wall_dict(level.walls, level.width, level.height),
        "solutionPath": [{"x": int(x), "y": int(y)} for x, y in path_xy],
    }


def _write_attempt_report(path: Path, payload: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def verify_level(level: LevelDef, image_path: Path, level_outdir: Path, max_attempts_per_level: int = 200) -> LevelVerification:
    return verify_level_solve_gated(level, image_path, level_outdir, max_attempts_per_level=max_attempts_per_level)


def verify_level_solve_gated(
    level: LevelDef,
    image_path: Path,
    level_outdir: Path,
    max_attempts_per_level: int = 200,
) -> LevelVerification:
    started = time.time()
    level_outdir.mkdir(parents=True, exist_ok=True)
    attempts_dir = level_outdir / "attempts"
    attempts_dir.mkdir(parents=True, exist_ok=True)

    bgr = cv2.imread(str(image_path))
    if bgr is None:
        _save_failure_artifacts(image_path, level_outdir)
        return LevelVerification(
            level_id=level.id,
            grid_size={"w": level.width, "h": level.height},
            image_file=image_path.name,
            clues_ok=False,
            clue_missing=sorted(_clue_tuples_from_level(level)),
            clue_extra=[],
            clue_uncertain_numbers=[],
            walls_ok=False,
            walls_missing=sorted(level.walls),
            walls_extra=[],
            solver_status="UNSOLVABLE",
            solver_path=[],
            solver_explored_nodes=0,
            solver_dead_states=0,
            solver_strategy="",
            attempts_count=1,
            duration_ms=int((time.time() - started) * 1000),
            repaired=False,
            failure_reason="Could not read image",
        )

    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    original = level
    working = level
    expected = sorted(level.clues)
    if (not expected) or expected[0] != 1 or expected != list(range(1, expected[-1] + 1)):
        expected = []
    solver_cache: Dict[Tuple[Tuple[Any, ...], str], SolverResult] = {}

    attempt = 0
    while True:
        attempt += 1
        stage_idx = (attempt - 1) % 3
        strategy_idx = (attempt - 1) // max(1, max_attempts_per_level)
        strategy = _solver_strategies()[strategy_idx % len(_solver_strategies())]

        try:
            grid = detect_grid_size_from_image(
                gray,
                preferred_size=(working.width, working.height),
                min_size=5,
                max_size=9,
            )
        except Exception as exc:
            try:
                grid = detect_grid(gray, working.width, working.height)
            except Exception:
                grid = fallback_grid_from_bbox(gray, working.width, working.height)

        if (grid.width, grid.height) != (working.width, working.height):
            working = _resize_level(working, grid.width, grid.height)

        clue_det = detect_clues(
            bgr,
            gray,
            grid,
            expected_numbers=expected,
            prior_clues=working.clues,
            variant=attempt - 1,
        )
        if not expected and clue_det.tuples:
            detected_nums = sorted({n for n, _, _ in clue_det.tuples if n > 0})
            if detected_nums and detected_nums[0] == 1:
                max_n = detected_nums[-1]
                expected = list(range(1, max_n + 1))
                inferred = _clue_map_from_detection(clue_det, expected)
                if inferred:
                    working = replace(working, clues=inferred)
        detected_walls = {
            e
            for e in detect_walls(gray, grid, variant=attempt - 1)
            if is_edge_valid(e, working.width, working.height)
        }

        expected_set = set(expected)
        expected_clues = _clue_tuples_from_level(working)
        detected_clues = {(n, x, y) for n, x, y in clue_det.tuples if n in expected_set}
        clue_missing = sorted(expected_clues - detected_clues)
        clue_extra = sorted(detected_clues - expected_clues)
        clues_ok = (
            not clue_missing
            and not clue_extra
            and not clue_det.uncertain_numbers
            and clue_det.expected_count == len(expected)
        )

        walls_missing = sorted(working.walls - detected_walls)
        walls_extra = sorted(detected_walls - working.walls)
        walls_ok = not walls_missing and not walls_extra

        sig = _level_signature(working)
        key = (sig, strategy)
        solver_result = solver_cache.get(key)
        if solver_result is None:
            solver_result = solve_level_with_stats(working, strategy=strategy)
            solver_cache[key] = solver_result
        solved = solver_result.path is not None
        solver_path_xy = [cell_to_xy(c, working.width) for c in (solver_result.path or [])]

        prefix = f"attempt_{attempt:04d}"
        draw_level_artifacts(
            image_path,
            grid,
            working,
            clue_det,
            detected_walls,
            attempts_dir / f"{prefix}_annotated.png",
            attempts_dir / f"{prefix}_walls_diff.png",
        )
        draw_solver_path_overlay(
            image_path,
            grid,
            solver_path_xy,
            attempts_dir / f"{prefix}_solver_path.png",
        )
        _write_attempt_report(
            attempts_dir / f"{prefix}.json",
            {
                "attempt": attempt,
                "strategy": strategy,
                "stage": ["repair_clues", "repair_walls_add", "repair_minimal"][stage_idx],
                "working_size": {"w": working.width, "h": working.height},
                "detected_size": {"w": grid.width, "h": grid.height},
                "clues_ok": clues_ok,
                "clue_missing": [list(v) for v in clue_missing],
                "clue_extra": [list(v) for v in clue_extra],
                "clue_uncertain_numbers": clue_det.uncertain_numbers,
                "walls_ok": walls_ok,
                "walls_missing": [list(v) for v in walls_missing],
                "walls_extra": [list(v) for v in walls_extra],
                "solver_status": "SOLVED" if solved else "UNSOLVABLE",
                "solver_stats": {
                    "explored_nodes": solver_result.stats.explored_nodes,
                    "dead_states": solver_result.stats.dead_states,
                    "strategy": solver_result.stats.strategy,
                },
            },
        )

        if solved:
            draw_level_artifacts(
                image_path,
                grid,
                working,
                clue_det,
                detected_walls,
                level_outdir / "annotated.png",
                level_outdir / "walls_diff.png",
            )
            draw_solver_path_overlay(
                image_path,
                grid,
                solver_path_xy,
                level_outdir / "solver_path.png",
            )
            (level_outdir / "solution.json").write_text(
                json.dumps(_solution_payload(working, solver_path_xy), indent=2),
                encoding="utf-8",
            )
            result = LevelVerification(
                level_id=working.id,
                grid_size={"w": working.width, "h": working.height},
                image_file=image_path.name,
                clues_ok=clues_ok,
                clue_missing=clue_missing,
                clue_extra=clue_extra,
                clue_uncertain_numbers=clue_det.uncertain_numbers,
                walls_ok=walls_ok,
                walls_missing=walls_missing,
                walls_extra=walls_extra,
                solver_status="SOLVED",
                solver_path=solver_path_xy,
                solver_explored_nodes=solver_result.stats.explored_nodes,
                solver_dead_states=solver_result.stats.dead_states,
                solver_strategy=solver_result.stats.strategy,
                attempts_count=attempt,
                duration_ms=int((time.time() - started) * 1000),
                repaired=(_level_signature(working) != _level_signature(original)),
                failure_reason=None,
            )
            (level_outdir / "report.json").write_text(
                json.dumps(result.to_json(), indent=2),
                encoding="utf-8",
            )
            return result

        prev_sig = _level_signature(working)
        if stage_idx == 0:
            working = _repair_clues_stage(working, clue_det, expected, attempt)
        elif stage_idx == 1:
            working = _repair_walls_add_stage(working, detected_walls, attempt)
        else:
            working = _repair_minimal_stage(working, clue_det, detected_walls, expected, attempt)
            working = _repair_walls_remove_stage(working, detected_walls, attempt)

        if _level_signature(working) == prev_sig:
            if detected_walls:
                working = replace(
                    working,
                    walls=(
                        set(detected_walls)
                        if attempt % 2 == 0
                        else (set(working.walls) & set(detected_walls))
                    ),
                )
            det_clues = _clue_map_from_detection(clue_det, expected)
            if det_clues and attempt % 3 == 0:
                clues = dict(working.clues)
                for n in sorted(expected):
                    if n in det_clues and (n in clue_det.strong_numbers or attempt % 9 == 0):
                        clues = _apply_single_clue_move(clues, n, det_clues[n])
                working = replace(working, clues=clues)

        hard_attempt_cap = max(1, int(max_attempts_per_level)) * len(_solver_strategies())
        if attempt >= hard_attempt_cap:
            break

    draw_level_artifacts(
        image_path,
        grid,
        working,
        clue_det,
        detected_walls,
        level_outdir / "annotated.png",
        level_outdir / "walls_diff.png",
    )
    draw_solver_path_overlay(
        image_path,
        grid,
        [],
        level_outdir / "solver_path.png",
    )
    failure = LevelVerification(
        level_id=working.id,
        grid_size={"w": working.width, "h": working.height},
        image_file=image_path.name,
        clues_ok=clues_ok,
        clue_missing=clue_missing,
        clue_extra=clue_extra,
        clue_uncertain_numbers=clue_det.uncertain_numbers,
        walls_ok=walls_ok,
        walls_missing=walls_missing,
        walls_extra=walls_extra,
        solver_status="UNSOLVABLE",
        solver_path=[],
        solver_explored_nodes=solver_result.stats.explored_nodes,
        solver_dead_states=solver_result.stats.dead_states,
        solver_strategy=solver_result.stats.strategy,
        attempts_count=attempt,
        duration_ms=int((time.time() - started) * 1000),
        repaired=(_level_signature(working) != _level_signature(original)),
        failure_reason=f"Reached max attempts ({attempt}) without a solvable reconstruction",
    )
    (level_outdir / "report.json").write_text(
        json.dumps(failure.to_json(), indent=2),
        encoding="utf-8",
    )
    return failure
