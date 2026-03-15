import 'dart:math';

import 'package:flutter/material.dart';

import 'editor_commands.dart';
import 'editor_state.dart';

class EditorCanvas extends StatefulWidget {
  const EditorCanvas({
    super.key,
    required this.state,
    required this.onRequestClue,
    this.clueLabelBuilder,
  });

  final EditorState state;
  final Future<void> Function(Point<int> cell) onRequestClue;
  final String Function(int number)? clueLabelBuilder;

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  GridEdge? _lastDraggedEdge;
  bool? _dragWallValue;
  Point<int>? _selectOrigin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = min(
              constraints.maxWidth / widget.state.width,
              constraints.maxHeight / widget.state.height,
            );
            final boardSize = Size(
              cellSize * widget.state.width,
              cellSize * widget.state.height,
            );

            return Center(
              child: MouseRegion(
                onHover: (event) {
                  final hit = _hitTest(
                    event.localPosition,
                    boardSize,
                    widget.state.width,
                    widget.state.height,
                    widget.state.snapStrict,
                  );
                  widget.state.setHover(edge: hit.edge, cell: hit.cell);
                },
                onExit: (_) => widget.state.clearHover(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _handleTap(details.localPosition, boardSize),
                  onLongPressStart: (details) =>
                      _handleLongPress(details.localPosition, boardSize),
                  onPanStart: (details) =>
                      _handlePanStart(details.localPosition, boardSize),
                  onPanUpdate: (details) =>
                      _handlePanUpdate(details.localPosition, boardSize),
                  onPanEnd: (_) {
                    _lastDraggedEdge = null;
                    _dragWallValue = null;
                  },
                  child: CustomPaint(
                    size: boardSize,
                    painter: _EditorPainter(
                      state: widget.state,
                      cellSize: cellSize,
                      clueLabelBuilder: widget.clueLabelBuilder,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleTap(Offset local, Size boardSize) {
    final hit = _hitTest(
      local,
      boardSize,
      widget.state.width,
      widget.state.height,
      widget.state.snapStrict,
    );
    switch (widget.state.tool) {
      case EditorTool.walls:
        if (hit.edge != null) {
          widget.state.toggleWall(hit.edge!);
        }
        break;
      case EditorTool.erase:
        if (hit.edge != null) {
          widget.state.toggleWall(hit.edge!, value: false);
        } else if (hit.cell != null) {
          widget.state.setClue(hit.cell!.x, hit.cell!.y, null);
        }
        break;
      case EditorTool.clues:
        if (hit.cell != null) {
          widget.onRequestClue(hit.cell!);
        }
        break;
      case EditorTool.select:
        if (hit.cell == null) {
          _selectOrigin = null;
          return;
        }
        final n = widget.state.clueAt(hit.cell!.x, hit.cell!.y);
        if (_selectOrigin == null) {
          if (n != null) {
            _selectOrigin = hit.cell;
          }
          return;
        }
        final from = _selectOrigin!;
        final number = widget.state.clueAt(from.x, from.y);
        if (number == null) {
          _selectOrigin = null;
          return;
        }
        widget.state.setClue(from.x, from.y, null);
        widget.state.setClue(hit.cell!.x, hit.cell!.y, number);
        _selectOrigin = null;
        break;
    }
  }

  void _handleLongPress(Offset local, Size boardSize) {
    if (widget.state.tool != EditorTool.clues) {
      return;
    }
    final hit = _hitTest(
      local,
      boardSize,
      widget.state.width,
      widget.state.height,
      widget.state.snapStrict,
    );
    final cell = hit.cell;
    if (cell == null) {
      return;
    }
    widget.state.setClue(cell.x, cell.y, null);
  }

  void _handlePanStart(Offset local, Size boardSize) {
    final hit = _hitTest(
      local,
      boardSize,
      widget.state.width,
      widget.state.height,
      widget.state.snapStrict,
    );
    if (hit.edge == null) {
      return;
    }
    _lastDraggedEdge = hit.edge;
    if (widget.state.tool == EditorTool.erase) {
      _dragWallValue = false;
    } else if (widget.state.tool == EditorTool.walls) {
      _dragWallValue = true;
    }
    if (_dragWallValue != null) {
      widget.state.toggleWall(hit.edge!, value: _dragWallValue);
    }
  }

  void _handlePanUpdate(Offset local, Size boardSize) {
    if (_dragWallValue == null) {
      return;
    }
    final hit = _hitTest(
      local,
      boardSize,
      widget.state.width,
      widget.state.height,
      widget.state.snapStrict,
    );
    if (hit.edge == null || hit.edge == _lastDraggedEdge) {
      return;
    }
    _lastDraggedEdge = hit.edge;
    widget.state.toggleWall(hit.edge!, value: _dragWallValue);
  }
}

class _CanvasHit {
  const _CanvasHit({this.edge, this.cell});

  final GridEdge? edge;
  final Point<int>? cell;
}

_CanvasHit _hitTest(
  Offset local,
  Size boardSize,
  int width,
  int height,
  bool snapStrict,
) {
  if (local.dx < 0 ||
      local.dy < 0 ||
      local.dx >= boardSize.width ||
      local.dy >= boardSize.height) {
    return const _CanvasHit();
  }

  final cellSize = boardSize.width / width;
  final gx = local.dx / cellSize;
  final gy = local.dy / cellSize;

  final nearestX = gx.round();
  final nearestY = gy.round();
  final distToV = (gx - nearestX).abs() * cellSize;
  final distToH = (gy - nearestY).abs() * cellSize;
  final threshold = snapStrict ? cellSize * 0.18 : cellSize * 0.28;

  if (min(distToV, distToH) <= threshold) {
    if (distToV <= distToH) {
      final x = nearestX;
      final y = gy.floor();
      if (x >= 0 && x <= width && y >= 0 && y < height) {
        return _CanvasHit(
          edge: GridEdge(type: EdgeType.vertical, x: x, y: y),
        );
      }
    } else {
      final x = gx.floor();
      final y = nearestY;
      if (x >= 0 && x < width && y >= 0 && y <= height) {
        return _CanvasHit(
          edge: GridEdge(type: EdgeType.horizontal, x: x, y: y),
        );
      }
    }
  }

  final cx = gx.floor();
  final cy = gy.floor();
  if (cx >= 0 && cx < width && cy >= 0 && cy < height) {
    return _CanvasHit(cell: Point<int>(cx, cy));
  }
  return const _CanvasHit();
}

class _EditorPainter extends CustomPainter {
  const _EditorPainter({
    required this.state,
    required this.cellSize,
    required this.clueLabelBuilder,
  });

  final EditorState state;
  final double cellSize;
  final String Function(int number)? clueLabelBuilder;

  @override
  void paint(Canvas canvas, Size size) {
    final boardRect = Offset.zero & size;
    final borderPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(
      boardRect,
      Paint()..color = Colors.white,
    );

    final gridPaint = Paint()
      ..color =
          state.previewMode ? const Color(0xFFD8D8D8) : const Color(0xFFE5E5E5)
      ..strokeWidth = 1;

    for (var i = 0; i <= state.width; i++) {
      final p = i * cellSize;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), gridPaint);
    }
    for (var i = 0; i <= state.height; i++) {
      final p = i * cellSize;
      canvas.drawLine(Offset(0, p), Offset(size.width, p), gridPaint);
    }

    if (state.hoverCell != null) {
      final cell = state.hoverCell!;
      final rect = Rect.fromLTWH(
        cell.x * cellSize,
        cell.y * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0x11000000),
      );
    }

    if (state.hoverEdge != null) {
      final edge = state.hoverEdge!;
      final highlight = Paint()
        ..color = const Color(0x33000000)
        ..strokeCap = StrokeCap.square
        ..strokeWidth = max(4, cellSize * 0.14);
      if (edge.type == EdgeType.horizontal) {
        final y = edge.y * cellSize;
        final x1 = edge.x * cellSize;
        final x2 = (edge.x + 1) * cellSize;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), highlight);
      } else {
        final x = edge.x * cellSize;
        final y1 = edge.y * cellSize;
        final y2 = (edge.y + 1) * cellSize;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), highlight);
      }
    }

    final wallPaint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.square
      ..strokeWidth = max(5, cellSize * 0.12);

    for (var y = 0; y <= state.height; y++) {
      for (var x = 0; x < state.width; x++) {
        if (!state.hWalls[y][x]) {
          continue;
        }
        final yPx = y * cellSize;
        final x1 = x * cellSize;
        final x2 = (x + 1) * cellSize;
        canvas.drawLine(Offset(x1, yPx), Offset(x2, yPx), wallPaint);
      }
    }

    for (var y = 0; y < state.height; y++) {
      for (var x = 0; x <= state.width; x++) {
        if (!state.vWalls[y][x]) {
          continue;
        }
        final xPx = x * cellSize;
        final y1 = y * cellSize;
        final y2 = (y + 1) * cellSize;
        canvas.drawLine(Offset(xPx, y1), Offset(xPx, y2), wallPaint);
      }
    }

    for (final entry in state.clues.entries) {
      final point = entry.key;
      final number = entry.value;
      final center = Offset(
        (point.x + 0.5) * cellSize,
        (point.y + 0.5) * cellSize,
      );
      canvas.drawCircle(
        center,
        cellSize * 0.24,
        Paint()..color = Colors.black,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: clueLabelBuilder?.call(number) ?? number.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: cellSize * 0.26,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }

    canvas.drawRect(boardRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _EditorPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.clueLabelBuilder != clueLabelBuilder;
  }
}
