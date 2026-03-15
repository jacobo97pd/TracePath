from __future__ import annotations

import unittest

import cv2
import numpy as np

from tool.verify_levels_core import (
    LevelDef,
    canonical_edge,
    detect_grid,
    detect_grid_size_from_image,
    detect_walls,
    edge_to_wall_coord,
    pixel_to_cell,
    solve_level,
    wall_coord_to_edge,
)


def make_synthetic_board(
    width: int,
    height: int,
    cell: int = 40,
    margin: int = 24,
    walls: set[tuple[int, int]] | None = None,
) -> np.ndarray:
    walls = walls or set()
    img_h = margin * 2 + cell * height
    img_w = margin * 2 + cell * width
    bgr = np.full((img_h, img_w, 3), 242, dtype=np.uint8)

    # Grid.
    grid_color = (170, 170, 170)
    for x in range(width + 1):
        px = margin + x * cell
        cv2.line(bgr, (px, margin), (px, margin + height * cell), grid_color, 1)
    for y in range(height + 1):
        py = margin + y * cell
        cv2.line(bgr, (margin, py), (margin + width * cell, py), grid_color, 1)

    # Thick walls.
    for e in walls:
        axis, x, y = edge_to_wall_coord(e, width, height)
        if axis == "h":
            px = margin + (x + 1) * cell
            py0 = margin + y * cell
            py1 = margin + (y + 1) * cell
            cv2.line(bgr, (px, py0), (px, py1), (0, 0, 0), 6)
        else:
            py = margin + (y + 1) * cell
            px0 = margin + x * cell
            px1 = margin + (x + 1) * cell
            cv2.line(bgr, (px0, py), (px1, py), (0, 0, 0), 6)

    return bgr


class WallEncodingTests(unittest.TestCase):
    def test_wall_edge_roundtrip_non_square(self) -> None:
        width = 6
        height = 7
        cases = [
            ("v", 1, 0),
            ("v", 5, 5),
            ("v", 3, 2),
            ("h", 0, 1),
            ("h", 4, 6),
            ("h", 2, 4),
        ]
        for axis, x, y in cases:
            edge = wall_coord_to_edge(axis, x, y, width, height)
            back = edge_to_wall_coord(edge, width, height)
            self.assertEqual((axis, x, y), back)


class SolverTests(unittest.TestCase):
    def test_solver_finds_valid_path(self) -> None:
        level = LevelDef(
            id="s1",
            width=2,
            height=2,
            clues={1: (0, 0), 2: (1, 0), 3: (0, 1)},
            walls=set(),
        )
        path = solve_level(level)
        self.assertIsNotNone(path)
        self.assertEqual(len(path or []), 4)
        self.assertEqual(path[0], 0)
        self.assertEqual(path[-1], 2)  # cell(0,1) == 2

    def test_solver_unsolvable_with_blocking_walls(self) -> None:
        # isolate start cell 0 from 1 and 2
        level = LevelDef(
            id="s2",
            width=2,
            height=2,
            clues={1: (0, 0), 2: (1, 1)},
            walls={canonical_edge(0, 1), canonical_edge(0, 2)},
        )
        self.assertIsNone(solve_level(level))

    def test_solver_rejects_non_consecutive_clues(self) -> None:
        level = LevelDef(
            id="s3",
            width=2,
            height=2,
            clues={1: (0, 0), 3: (1, 1)},
            walls=set(),
        )
        self.assertIsNone(solve_level(level))


class MappingTests(unittest.TestCase):
    def test_grid_mapping_and_wall_detection_on_synthetic(self) -> None:
        width, height = 6, 7
        expected_walls = {
            wall_coord_to_edge("v", 3, 2, width, height),
            wall_coord_to_edge("h", 1, 4, width, height),
        }
        bgr = make_synthetic_board(width, height, walls=expected_walls)
        gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)

        grid = detect_grid(gray, width, height)
        self.assertEqual(len(grid.x_lines), width + 1)
        self.assertEqual(len(grid.y_lines), height + 1)

        cx = (grid.x_lines[2] + grid.x_lines[3]) // 2
        cy = (grid.y_lines[5] + grid.y_lines[6]) // 2
        self.assertEqual(pixel_to_cell(cx, cy, grid), (2, 5))

        detected = detect_walls(gray, grid)
        self.assertTrue(expected_walls.issubset(detected))

    def test_grid_size_detector_synthetic(self) -> None:
        for width, height in [(6, 6), (6, 7), (7, 7)]:
            bgr = make_synthetic_board(width, height)
            gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
            grid = detect_grid_size_from_image(gray, preferred_size=(width, height))
            self.assertEqual(grid.width, width)
            self.assertEqual(grid.height, height)


if __name__ == "__main__":
    unittest.main()
