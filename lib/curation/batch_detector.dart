import 'dart:ui';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../engine/level.dart';
import 'batch_models.dart';

class DetectionResult {
  const DetectionResult({
    required this.gridSize,
    required this.confidence,
    required this.confidenceBoard,
    required this.confidenceGrid,
    required this.confidenceWalls,
    required this.confidenceTrim,
    required this.notes,
    required this.clues,
    required this.walls,
    required this.alignment,
  });

  final int gridSize;
  final double confidence;
  final double confidenceBoard;
  final double confidenceGrid;
  final double confidenceWalls;
  final double confidenceTrim;
  final String notes;
  final List<CurationClue> clues;
  final List<Wall> walls;
  final GridAlignment alignment;
}

class BatchAutoDetector {
  const BatchAutoDetector();

  DetectionResult detect(Uint8List bytes, {required String fileName}) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return _fallback('Decode failed');
    }

    final resized = _resizeForProcessing(decoded);
    final gray = _toGray(resized);
    final edge = _edgeMagnitude(gray, resized.width, resized.height);

    final board = _detectBoardRect(gray, edge, resized.width, resized.height);
    final trimmed = _trimBottomUiBand(
      gray: gray,
      edge: edge,
      width: resized.width,
      height: resized.height,
      rect: board.rect,
      spacingHint: board.spacingHint,
    );

    final projections = _analyzeGridSpacing(
      edge: edge,
      width: resized.width,
      height: resized.height,
      rect: trimmed.rect,
    );

    final gridN = _estimateGridSize(trimmed.rect, projections.cellSize);
    final cellSize = math.max(4.0, trimmed.rect.width / gridN);

    final darkThreshold = _percentile(
      _extractRect(gray, resized.width, trimmed.rect),
      0.20,
    ).toDouble();

    final walls = _detectWalls(
      gray: gray,
      width: resized.width,
      rect: trimmed.rect,
      gridN: gridN,
      darkThreshold: darkThreshold,
      cellSize: cellSize,
    );

    final clues = _detectClueCells(
      gray: gray,
      width: resized.width,
      rect: trimmed.rect,
      gridN: gridN,
      darkThreshold: darkThreshold,
      cellSize: cellSize,
    );

    final confidenceGrid = projections.confidence;
    final confidenceBoard = board.confidence;
    final confidenceTrim = trimmed.confidence;
    final confidenceWalls = _wallsConfidence(
      walls: walls,
      gridN: gridN,
      gray: gray,
      width: resized.width,
      rect: trimmed.rect,
      darkThreshold: darkThreshold,
    );

    final confidence = _clamp01(
      (confidenceBoard * 0.30) +
          (confidenceGrid * 0.30) +
          (confidenceWalls * 0.30) +
          (confidenceTrim * 0.10),
    );

    final alignment = GridAlignment(
      left: trimmed.rect.left / resized.width,
      top: trimmed.rect.top / resized.height,
      right: trimmed.rect.right / resized.width,
      bottom: trimmed.rect.bottom / resized.height,
    );

    return DetectionResult(
      gridSize: gridN,
      confidence: confidence,
      confidenceBoard: confidenceBoard,
      confidenceGrid: confidenceGrid,
      confidenceWalls: confidenceWalls,
      confidenceTrim: confidenceTrim,
      notes:
          'board=${confidenceBoard.toStringAsFixed(2)} grid=${confidenceGrid.toStringAsFixed(2)} walls=${confidenceWalls.toStringAsFixed(2)} trim=${confidenceTrim.toStringAsFixed(2)} clues=${clues.length}',
      clues: clues,
      walls: walls,
      alignment: alignment,
    );
  }

  DetectionResult _fallback(String notes) {
    return DetectionResult(
      gridSize: 8,
      confidence: 0.0,
      confidenceBoard: 0.0,
      confidenceGrid: 0.0,
      confidenceWalls: 0.0,
      confidenceTrim: 0.0,
      notes: notes,
      clues: const <CurationClue>[],
      walls: const <Wall>[],
      alignment: GridAlignment.defaults,
    );
  }

  img.Image _resizeForProcessing(img.Image src) {
    final maxDim = math.max(src.width, src.height);
    if (maxDim <= 900) {
      return src;
    }
    final scale = 900.0 / maxDim;
    return img.copyResize(
      src,
      width: (src.width * scale).round(),
      height: (src.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  List<int> _toGray(img.Image image) {
    final out = List<int>.filled(image.width * image.height, 0);
    var i = 0;
    for (final pixel in image) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      out[i++] = ((r * 299 + g * 587 + b * 114) ~/ 1000).clamp(0, 255);
    }
    return out;
  }

  List<int> _edgeMagnitude(List<int> gray, int width, int height) {
    final edge = List<int>.filled(width * height, 0);
    for (var y = 1; y < height - 1; y++) {
      final yw = y * width;
      for (var x = 1; x < width - 1; x++) {
        final i = yw + x;
        final dx = (gray[i + 1] - gray[i - 1]).abs();
        final dy = (gray[i + width] - gray[i - width]).abs();
        edge[i] = (dx + dy).clamp(0, 255);
      }
    }
    return edge;
  }

  _BoardDetection _detectBoardRect(
    List<int> gray,
    List<int> edge,
    int width,
    int height,
  ) {
    final threshold = _percentile(edge, 0.86);
    final mask = List<bool>.filled(width * height, false);
    for (var i = 0; i < edge.length; i++) {
      mask[i] = edge[i] >= threshold;
    }

    final candidates = <Rect>[];
    candidates.addAll(_componentCandidates(mask, width, height));
    candidates.addAll(_fallbackSquareCandidates(width, height));

    var bestRect = Rect.fromLTWH(
      width * 0.12,
      height * 0.18,
      math.min(width, height) * 0.76,
      math.min(width, height) * 0.76,
    );
    var bestScore = -1e9;
    var bestSpacing = 0.0;

    for (final rect in candidates) {
      final score = _gridnessScore(
        gray: gray,
        edge: edge,
        width: width,
        height: height,
        rect: rect,
      );
      if (score.score > bestScore) {
        bestScore = score.score;
        bestRect = rect;
        bestSpacing = score.spacing;
      }
    }

    final normalizedScore = _clamp01((bestScore + 0.3) / 1.4);
    return _BoardDetection(
      rect: bestRect,
      confidence: normalizedScore,
      spacingHint: bestSpacing,
    );
  }

  List<Rect> _componentCandidates(List<bool> mask, int width, int height) {
    final visited = List<bool>.filled(mask.length, false);
    final out = <Rect>[];
    final minDim = math.min(width, height);
    final minSize = minDim * 0.35;

    for (var i = 0; i < mask.length; i++) {
      if (!mask[i] || visited[i]) {
        continue;
      }
      final queue = <int>[i];
      visited[i] = true;
      var qIdx = 0;
      var minX = width;
      var minY = height;
      var maxX = 0;
      var maxY = 0;
      var count = 0;

      while (qIdx < queue.length) {
        final p = queue[qIdx++];
        final x = p % width;
        final y = p ~/ width;
        count++;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;

        void push(int nx, int ny) {
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) return;
          final ni = ny * width + nx;
          if (visited[ni] || !mask[ni]) return;
          visited[ni] = true;
          queue.add(ni);
        }

        push(x - 1, y);
        push(x + 1, y);
        push(x, y - 1);
        push(x, y + 1);
      }

      final w = (maxX - minX + 1).toDouble();
      final h = (maxY - minY + 1).toDouble();
      final aspect = w / h;
      if (w < minSize || h < minSize) {
        continue;
      }
      if (aspect < 0.85 || aspect > 1.15) {
        continue;
      }
      if (count < 200) {
        continue;
      }

      final padX = w * 0.04;
      final padY = h * 0.04;
      out.add(
        Rect.fromLTRB(
          (minX - padX).clamp(0, width - 1).toDouble(),
          (minY - padY).clamp(0, height - 1).toDouble(),
          (maxX + 1 + padX).clamp(1, width).toDouble(),
          (maxY + 1 + padY).clamp(1, height).toDouble(),
        ),
      );
    }

    return out;
  }

  List<Rect> _fallbackSquareCandidates(int width, int height) {
    final out = <Rect>[];
    final minDim = math.min(width, height).toDouble();
    const scales = <double>[0.55, 0.65, 0.75, 0.85];
    const yOffsets = <double>[-0.15, -0.08, 0.0, 0.08];

    for (final scale in scales) {
      final side = minDim * scale;
      final cx = width / 2;
      for (final yo in yOffsets) {
        final cy = (height / 2) + yo * minDim;
        final left = (cx - side / 2).clamp(0.0, width - side);
        final top = (cy - side / 2).clamp(0.0, height - side);
        out.add(Rect.fromLTWH(left, top, side, side));
      }
    }
    return out;
  }

  _GridnessScore _gridnessScore({
    required List<int> gray,
    required List<int> edge,
    required int width,
    required int height,
    required Rect rect,
  }) {
    final pv = _verticalProjection(edge, width, rect);
    final ph = _horizontalProjection(edge, width, rect);
    final vx = _projectionSpacing(pv);
    final hy = _projectionSpacing(ph);

    final darkThreshold = _percentile(_extractRect(gray, width, rect), 0.20);
    var darkPixels = 0;
    final total = math.max(1, rect.width.round() * rect.height.round());
    for (var y = rect.top.round(); y < rect.bottom.round(); y++) {
      for (var x = rect.left.round(); x < rect.right.round(); x++) {
        if (gray[y * width + x] <= darkThreshold) {
          darkPixels++;
        }
      }
    }
    final darkRatio = darkPixels / total;

    final spacing = (vx.spacing + hy.spacing) / 2;
    final periodic = ((vx.periodicity + hy.periodicity) / 2).clamp(0.0, 1.0);
    final consistency = 1.0 -
        ((vx.spacing - hy.spacing).abs() / math.max(1.0, spacing))
            .clamp(0.0, 1.0);
    final wallSignal = ((darkRatio - 0.04) / 0.18).clamp(0.0, 1.0);

    final score =
        (periodic * 0.45) + (consistency * 0.25) + (wallSignal * 0.30);

    return _GridnessScore(
      score: score,
      spacing: spacing,
    );
  }

  _TrimResult _trimBottomUiBand({
    required List<int> gray,
    required List<int> edge,
    required int width,
    required int height,
    required Rect rect,
    required double spacingHint,
  }) {
    final h = rect.height.round();
    final rowEnergy = List<double>.filled(h, 0);
    for (var y = 0; y < h; y++) {
      final yy = rect.top.round() + y;
      double sum = 0;
      for (var x = rect.left.round(); x < rect.right.round(); x++) {
        sum += edge[yy * width + x];
      }
      rowEnergy[y] = sum / math.max(1, rect.width);
    }

    final smooth = _smooth(rowEnergy, 4);
    final base = _percentileD(smooth, 0.45);
    final top = rect.top;
    var bottom = rect.bottom;
    var confidence = 0.55;

    final spacing =
        spacingHint > 2 ? spacingHint : math.max(8.0, rect.height / 8);
    final probeRows = math.max(5, (spacing * 0.9).round());
    for (var y = smooth.length - probeRows - 1; y > smooth.length * 0.55; y--) {
      final recent = smooth.sublist(y, math.min(smooth.length, y + probeRows));
      final mean = recent.reduce((a, b) => a + b) / recent.length;
      if (mean < base * 0.62) {
        bottom = top + y.toDouble();
        confidence = 0.85;
        break;
      }
    }

    final minBottom = top + rect.height * 0.72;
    if (bottom < minBottom) {
      bottom = rect.bottom;
      confidence = 0.45;
    }

    return _TrimResult(
      rect: Rect.fromLTRB(rect.left, rect.top, rect.right, bottom),
      confidence: confidence,
    );
  }

  _GridProjection _analyzeGridSpacing({
    required List<int> edge,
    required int width,
    required int height,
    required Rect rect,
  }) {
    final pv = _verticalProjection(edge, width, rect);
    final ph = _horizontalProjection(edge, width, rect);
    final vx = _projectionSpacing(pv);
    final hy = _projectionSpacing(ph);

    final cellSize = (vx.spacing + hy.spacing) / 2;
    final consistency = 1.0 -
        ((vx.spacing - hy.spacing).abs() / math.max(1.0, cellSize))
            .clamp(0.0, 1.0);
    final confidence = _clamp01(
        ((vx.periodicity + hy.periodicity) / 2) * 0.7 + consistency * 0.3);

    return _GridProjection(
      cellSize: cellSize,
      confidence: confidence,
    );
  }

  int _estimateGridSize(Rect rect, double cellSize) {
    if (cellSize <= 2) {
      return 8;
    }
    final estimated = (rect.width / cellSize).round().clamp(5, 12);
    const preferred = <int>[7, 8, 9];
    var best = estimated;
    var bestErr = 1e9;
    for (final n in preferred) {
      final err = (estimated - n).abs().toDouble();
      if (err < bestErr) {
        bestErr = err;
        best = n;
      }
    }
    if (bestErr <= 1.0) {
      return best;
    }
    return estimated;
  }

  List<Wall> _detectWalls({
    required List<int> gray,
    required int width,
    required Rect rect,
    required int gridN,
    required double darkThreshold,
    required double cellSize,
  }) {
    final walls = <Wall>[];
    final strip = math.max(3, (cellSize * 0.08).round()).toDouble();

    for (var y = 0; y < gridN; y++) {
      for (var x = 0; x < gridN; x++) {
        final cell = y * gridN + x;
        if (x < gridN - 1) {
          final nx = cell + 1;
          final fx = rect.left + (x + 1) * (rect.width / gridN);
          final fy1 = rect.top + y * (rect.height / gridN);
          final fy2 = rect.top + (y + 1) * (rect.height / gridN);
          final frac = _darkStripFraction(
            gray: gray,
            width: width,
            x0: fx - strip / 2,
            y0: fy1 + strip,
            x1: fx + strip / 2,
            y1: fy2 - strip,
            darkThreshold: darkThreshold,
          );
          if (frac > 0.60) {
            walls.add(Wall(cell1: cell, cell2: nx));
          }
        }
        if (y < gridN - 1) {
          final ny = cell + gridN;
          final fy = rect.top + (y + 1) * (rect.height / gridN);
          final fx1 = rect.left + x * (rect.width / gridN);
          final fx2 = rect.left + (x + 1) * (rect.width / gridN);
          final frac = _darkStripFraction(
            gray: gray,
            width: width,
            x0: fx1 + strip,
            y0: fy - strip / 2,
            x1: fx2 - strip,
            y1: fy + strip / 2,
            darkThreshold: darkThreshold,
          );
          if (frac > 0.60) {
            walls.add(Wall(cell1: cell, cell2: ny));
          }
        }
      }
    }

    final dedupe = <String, Wall>{};
    for (final w in walls) {
      final a = math.min(w.cell1, w.cell2);
      final b = math.max(w.cell1, w.cell2);
      dedupe['$a:$b'] = Wall(cell1: a, cell2: b);
    }
    final out = dedupe.values.toList(growable: false)
      ..sort((a, b) {
        final c = a.cell1.compareTo(b.cell1);
        if (c != 0) return c;
        return a.cell2.compareTo(b.cell2);
      });
    return out;
  }

  List<CurationClue> _detectClueCells({
    required List<int> gray,
    required int width,
    required Rect rect,
    required int gridN,
    required double darkThreshold,
    required double cellSize,
  }) {
    final clues = <CurationClue>[];
    final radius = cellSize * 0.28;

    for (var y = 0; y < gridN; y++) {
      for (var x = 0; x < gridN; x++) {
        final cx = rect.left + (x + 0.5) * (rect.width / gridN);
        final cy = rect.top + (y + 0.5) * (rect.height / gridN);

        var sumCenter = 0.0;
        var cntCenter = 0;
        var darkCenter = 0;
        final ri = radius.ceil();
        for (var oy = -ri; oy <= ri; oy++) {
          for (var ox = -ri; ox <= ri; ox++) {
            final d2 = ox * ox + oy * oy;
            if (d2 > radius * radius) continue;
            final px = (cx + ox).round();
            final py = (cy + oy).round();
            if (px < 0 || py < 0) continue;
            final idx = py * width + px;
            if (idx < 0 || idx >= gray.length) continue;
            final v = gray[idx];
            sumCenter += v;
            cntCenter++;
            if (v < darkThreshold) darkCenter++;
          }
        }
        if (cntCenter == 0) continue;
        final centerMean = sumCenter / cntCenter;
        final darkFraction = darkCenter / cntCenter;

        final ring = _sampleRingContrast(
          gray: gray,
          width: width,
          cx: cx,
          cy: cy,
          radius: radius,
        );

        if (centerMean < darkThreshold + 16 &&
            darkFraction > 0.52 &&
            ring > 14.0) {
          clues.add(CurationClue(n: 0, x: x, y: y));
        }
      }
    }

    return clues;
  }

  double _wallsConfidence({
    required List<Wall> walls,
    required int gridN,
    required List<int> gray,
    required int width,
    required Rect rect,
    required double darkThreshold,
  }) {
    final maxEdges = (gridN * (gridN - 1) * 2).toDouble();
    final density = walls.length / math.max(1.0, maxEdges);

    final nodeDegree = <int, int>{};
    for (final wall in walls) {
      nodeDegree[wall.cell1] = (nodeDegree[wall.cell1] ?? 0) + 1;
      nodeDegree[wall.cell2] = (nodeDegree[wall.cell2] ?? 0) + 1;
    }
    final continuity = nodeDegree.isEmpty
        ? 0.0
        : nodeDegree.values.where((d) => d >= 2).length / nodeDegree.length;

    var darkPixels = 0;
    var total = 0;
    for (var y = rect.top.round(); y < rect.bottom.round(); y++) {
      for (var x = rect.left.round(); x < rect.right.round(); x++) {
        final g = gray[y * width + x];
        total++;
        if (g < darkThreshold) darkPixels++;
      }
    }
    final darkRatio = darkPixels / math.max(1, total);

    return _clamp01(
        (density * 2.2) + (continuity * 0.45) + ((darkRatio - 0.03) * 1.4));
  }

  double _darkStripFraction({
    required List<int> gray,
    required int width,
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required double darkThreshold,
  }) {
    final left = math.min(x0, x1).round();
    final right = math.max(x0, x1).round();
    final top = math.min(y0, y1).round();
    final bottom = math.max(y0, y1).round();

    var dark = 0;
    var total = 0;
    for (var y = top; y <= bottom; y++) {
      if (y < 0) continue;
      for (var x = left; x <= right; x++) {
        if (x < 0) continue;
        final idx = y * width + x;
        if (idx < 0 || idx >= gray.length) continue;
        total++;
        if (gray[idx] < darkThreshold) dark++;
      }
    }
    if (total == 0) return 0;
    return dark / total;
  }

  double _sampleRingContrast({
    required List<int> gray,
    required int width,
    required double cx,
    required double cy,
    required double radius,
  }) {
    double sample(double r, double t) {
      final x = (cx + r * math.cos(t)).round();
      final y = (cy + r * math.sin(t)).round();
      final idx = y * width + x;
      if (idx < 0 || idx >= gray.length) return 255;
      return gray[idx].toDouble();
    }

    var ring = 0.0;
    var outer = 0.0;
    const points = 12;
    for (var i = 0; i < points; i++) {
      final t = (i / points) * math.pi * 2;
      ring += sample(radius, t);
      outer += sample(radius * 1.35, t);
    }
    ring /= points;
    outer /= points;
    return outer - ring;
  }

  List<double> _verticalProjection(List<int> edge, int width, Rect rect) {
    final left = rect.left.round();
    final right = rect.right.round();
    final top = rect.top.round();
    final bottom = rect.bottom.round();
    final out = List<double>.filled(math.max(1, right - left), 0);

    for (var x = left; x < right; x++) {
      var sum = 0.0;
      for (var y = top; y < bottom; y++) {
        sum += edge[y * width + x];
      }
      out[x - left] = sum / math.max(1, bottom - top);
    }
    return _smooth(out, 2);
  }

  List<double> _horizontalProjection(List<int> edge, int width, Rect rect) {
    final left = rect.left.round();
    final right = rect.right.round();
    final top = rect.top.round();
    final bottom = rect.bottom.round();
    final out = List<double>.filled(math.max(1, bottom - top), 0);

    for (var y = top; y < bottom; y++) {
      var sum = 0.0;
      for (var x = left; x < right; x++) {
        sum += edge[y * width + x];
      }
      out[y - top] = sum / math.max(1, right - left);
    }
    return _smooth(out, 2);
  }

  _SpacingStats _projectionSpacing(List<double> p) {
    final mean = p.isEmpty ? 0.0 : p.reduce((a, b) => a + b) / p.length;
    final threshold = mean * 1.18;
    final peaks = <int>[];
    for (var i = 2; i < p.length - 2; i++) {
      if (p[i] > threshold && p[i] > p[i - 1] && p[i] >= p[i + 1]) {
        peaks.add(i);
      }
    }

    if (peaks.length < 3) {
      return const _SpacingStats(spacing: 10.0, periodicity: 0.0);
    }

    final diffs = <int>[];
    for (var i = 1; i < peaks.length; i++) {
      final d = peaks[i] - peaks[i - 1];
      if (d >= 4 && d <= 220) {
        diffs.add(d);
      }
    }
    if (diffs.isEmpty) {
      return const _SpacingStats(spacing: 10.0, periodicity: 0.0);
    }

    final hist = <int, int>{};
    for (final d in diffs) {
      final bin = (d / 2).round() * 2;
      hist[bin] = (hist[bin] ?? 0) + 1;
    }

    var bestBin = hist.keys.first;
    var bestCount = hist[bestBin] ?? 0;
    hist.forEach((k, v) {
      if (v > bestCount) {
        bestCount = v;
        bestBin = k;
      }
    });

    final inliers = diffs.where((d) => (d - bestBin).abs() <= 3).length;
    final periodicity = inliers / diffs.length;

    return _SpacingStats(
      spacing: bestBin.toDouble().clamp(6.0, 180.0),
      periodicity: periodicity,
    );
  }

  List<double> _smooth(List<double> values, int radius) {
    if (values.isEmpty || radius <= 0) {
      return values;
    }
    final out = List<double>.filled(values.length, 0);
    for (var i = 0; i < values.length; i++) {
      var sum = 0.0;
      var count = 0;
      for (var d = -radius; d <= radius; d++) {
        final j = i + d;
        if (j < 0 || j >= values.length) continue;
        sum += values[j];
        count++;
      }
      out[i] = sum / math.max(1, count);
    }
    return out;
  }

  List<int> _extractRect(List<int> values, int width, Rect rect) {
    final out = <int>[];
    for (var y = rect.top.round(); y < rect.bottom.round(); y++) {
      for (var x = rect.left.round(); x < rect.right.round(); x++) {
        out.add(values[y * width + x]);
      }
    }
    return out;
  }

  int _percentile(List<int> values, double q) {
    if (values.isEmpty) return 0;
    final sorted = List<int>.from(values)..sort();
    final idx = ((sorted.length - 1) * q).round().clamp(0, sorted.length - 1);
    return sorted[idx];
  }

  double _percentileD(List<double> values, double q) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final idx = ((sorted.length - 1) * q).round().clamp(0, sorted.length - 1);
    return sorted[idx];
  }

  double _clamp01(double v) {
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }
}

class _BoardDetection {
  const _BoardDetection({
    required this.rect,
    required this.confidence,
    required this.spacingHint,
  });

  final Rect rect;
  final double confidence;
  final double spacingHint;
}

class _TrimResult {
  const _TrimResult({required this.rect, required this.confidence});

  final Rect rect;
  final double confidence;
}

class _GridProjection {
  const _GridProjection({required this.cellSize, required this.confidence});

  final double cellSize;
  final double confidence;
}

class _GridnessScore {
  const _GridnessScore({required this.score, required this.spacing});

  final double score;
  final double spacing;
}

class _SpacingStats {
  const _SpacingStats({required this.spacing, required this.periodicity});

  final double spacing;
  final double periodicity;
}
