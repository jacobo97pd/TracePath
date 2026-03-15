import 'dart:convert';

import '../engine/level.dart';

enum BatchItemStatus {
  imported,
  autoDetected,
  needsNumbering,
  needsQa,
  valid,
  invalid,
  exported,
}

class CurationClue {
  const CurationClue({required this.n, required this.x, required this.y});

  final int n;
  final int x;
  final int y;

  Map<String, dynamic> toJson() => <String, dynamic>{'n': n, 'x': x, 'y': y};

  factory CurationClue.fromJson(Map<String, dynamic> json) => CurationClue(
        n: (json['n'] as num).toInt(),
        x: (json['x'] as num).toInt(),
        y: (json['y'] as num).toInt(),
      );
}

class GridAlignment {
  const GridAlignment({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  GridAlignment copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return GridAlignment(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };

  factory GridAlignment.fromJson(Map<String, dynamic> json) => GridAlignment(
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        right: (json['right'] as num).toDouble(),
        bottom: (json['bottom'] as num).toDouble(),
      );

  static const GridAlignment defaults = GridAlignment(
    left: 0.08,
    top: 0.08,
    right: 0.92,
    bottom: 0.92,
  );
}

class CurationBatchItem {
  const CurationBatchItem({
    required this.id,
    required this.fileName,
    required this.imageBytes,
    required this.gridSize,
    required this.clues,
    required this.walls,
    required this.status,
    required this.confidence,
    required this.confidenceBoard,
    required this.confidenceGrid,
    required this.confidenceWalls,
    required this.confidenceTrim,
    required this.alignment,
    required this.notes,
    required this.fingerprint,
    required this.solution,
    required this.lastValidation,
  });

  final String id;
  final String fileName;
  final String? imageBytes;
  final int gridSize;
  final List<CurationClue> clues;
  final List<Wall> walls;
  final BatchItemStatus status;
  final double confidence;
  final double confidenceBoard;
  final double confidenceGrid;
  final double confidenceWalls;
  final double confidenceTrim;
  final GridAlignment alignment;
  final String notes;
  final String? fingerprint;
  final List<int> solution;
  final String? lastValidation;

  CurationBatchItem copyWith({
    String? id,
    String? fileName,
    String? imageBytes,
    bool clearImageBytes = false,
    int? gridSize,
    List<CurationClue>? clues,
    List<Wall>? walls,
    BatchItemStatus? status,
    double? confidence,
    double? confidenceBoard,
    double? confidenceGrid,
    double? confidenceWalls,
    double? confidenceTrim,
    GridAlignment? alignment,
    String? notes,
    String? fingerprint,
    List<int>? solution,
    String? lastValidation,
  }) {
    return CurationBatchItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      imageBytes: clearImageBytes ? null : (imageBytes ?? this.imageBytes),
      gridSize: gridSize ?? this.gridSize,
      clues: clues ?? this.clues,
      walls: walls ?? this.walls,
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      confidenceBoard: confidenceBoard ?? this.confidenceBoard,
      confidenceGrid: confidenceGrid ?? this.confidenceGrid,
      confidenceWalls: confidenceWalls ?? this.confidenceWalls,
      confidenceTrim: confidenceTrim ?? this.confidenceTrim,
      alignment: alignment ?? this.alignment,
      notes: notes ?? this.notes,
      fingerprint: fingerprint ?? this.fingerprint,
      solution: solution ?? this.solution,
      lastValidation: lastValidation ?? this.lastValidation,
    );
  }

  Map<String, dynamic> toJson({bool includeImageBytes = false}) {
    return <String, dynamic>{
      'id': id,
      'fileName': fileName,
      if (includeImageBytes) 'imageBytes': imageBytes,
      'gridSize': gridSize,
      'clues': clues.map((e) => e.toJson()).toList(growable: false),
      'walls': walls.map((e) => e.toJson()).toList(growable: false),
      'status': status.name,
      'confidence': confidence,
      'confidenceBoard': confidenceBoard,
      'confidenceGrid': confidenceGrid,
      'confidenceWalls': confidenceWalls,
      'confidenceTrim': confidenceTrim,
      'alignment': alignment.toJson(),
      'notes': notes,
      'fingerprint': fingerprint,
      'solution': solution,
      'lastValidation': lastValidation,
    };
  }

  factory CurationBatchItem.fromJson(Map<String, dynamic> json) {
    return CurationBatchItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      imageBytes: json['imageBytes'] as String?,
      gridSize: (json['gridSize'] as num).toInt(),
      clues: ((json['clues'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
              (e) => CurationClue.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      walls: ((json['walls'] as List<dynamic>?) ?? const <dynamic>[])
          .map((e) => Wall.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
      status: BatchItemStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => BatchItemStatus.imported,
      ),
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
      confidenceBoard: ((json['confidenceBoard'] as num?) ?? 0).toDouble(),
      confidenceGrid: ((json['confidenceGrid'] as num?) ?? 0).toDouble(),
      confidenceWalls: ((json['confidenceWalls'] as num?) ?? 0).toDouble(),
      confidenceTrim: ((json['confidenceTrim'] as num?) ?? 0).toDouble(),
      alignment: json['alignment'] == null
          ? GridAlignment.defaults
          : GridAlignment.fromJson(
              Map<String, dynamic>.from(json['alignment'] as Map)),
      notes: (json['notes'] as String?) ?? '',
      fingerprint: json['fingerprint'] as String?,
      solution: ((json['solution'] as List<dynamic>?) ?? const <dynamic>[])
          .map((e) => (e as num).toInt())
          .toList(growable: false),
      lastValidation: json['lastValidation'] as String?,
    );
  }
}

class BatchSessionSnapshot {
  const BatchSessionSnapshot({required this.items});

  final List<CurationBatchItem> items;

  Map<String, dynamic> toJson({bool includeImageBytes = false}) =>
      <String, dynamic>{
        'schema': 'batch-curate-v1',
        'items': items
            .map((e) => e.toJson(includeImageBytes: includeImageBytes))
            .toList(growable: false),
      };

  String toJsonString({bool includeImageBytes = false}) =>
      jsonEncode(toJson(includeImageBytes: includeImageBytes));

  factory BatchSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final items = ((json['items'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) =>
            CurationBatchItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
    return BatchSessionSnapshot(items: items);
  }
}

class ValidationResult {
  const ValidationResult({
    required this.valid,
    required this.reason,
    required this.solutionCount,
    required this.solution,
    required this.fingerprint,
  });

  final bool valid;
  final String reason;
  final int solutionCount;
  final List<int> solution;
  final String? fingerprint;
}
