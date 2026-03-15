import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'editor_codec.dart';
import 'editor_commands.dart';
import 'editor_validator.dart';

enum EditorTool {
  walls,
  clues,
  erase,
  select,
}

class EditorState extends ChangeNotifier implements EditorMutator {
  EditorState({int initialWidth = 7, int initialHeight = 7})
      : _width = initialWidth,
        _height = initialHeight {
    _hWalls = List.generate(
      _height + 1,
      (_) => List<bool>.filled(_width, false),
      growable: false,
    );
    _vWalls = List.generate(
      _height,
      (_) => List<bool>.filled(_width + 1, false),
      growable: false,
    );
  }

  int _width;
  int _height;
  late List<List<bool>> _hWalls;
  late List<List<bool>> _vWalls;
  final Map<Point<int>, int> _clues = <Point<int>, int>{};

  final List<EditorCommand> _undoStack = <EditorCommand>[];
  final List<EditorCommand> _redoStack = <EditorCommand>[];

  EditorTool _tool = EditorTool.walls;
  bool _autoNumber = true;
  bool _snapStrict = true;
  bool _previewMode = false;

  GridEdge? _hoverEdge;
  Point<int>? _hoverCell;

  @override
  int get width => _width;

  @override
  int get height => _height;

  EditorTool get tool => _tool;

  bool get autoNumber => _autoNumber;

  bool get snapStrict => _snapStrict;

  bool get previewMode => _previewMode;

  GridEdge? get hoverEdge => _hoverEdge;

  Point<int>? get hoverCell => _hoverCell;

  List<List<bool>> get hWalls => _hWalls;

  List<List<bool>> get vWalls => _vWalls;

  Map<Point<int>, int> get clues =>
      UnmodifiableMapView<Point<int>, int>(_clues);

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  void setTool(EditorTool tool) {
    if (_tool == tool) {
      return;
    }
    _tool = tool;
    notifyListeners();
  }

  void setAutoNumber(bool value) {
    if (_autoNumber == value) {
      return;
    }
    _autoNumber = value;
    notifyListeners();
  }

  void setSnapStrict(bool value) {
    if (_snapStrict == value) {
      return;
    }
    _snapStrict = value;
    notifyListeners();
  }

  void setPreviewMode(bool value) {
    if (_previewMode == value) {
      return;
    }
    _previewMode = value;
    notifyListeners();
  }

  void setHover({GridEdge? edge, Point<int>? cell}) {
    final sameEdge = edge == _hoverEdge;
    final sameCell = cell == _hoverCell;
    if (sameEdge && sameCell) {
      return;
    }
    _hoverEdge = edge;
    _hoverCell = cell;
    notifyListeners();
  }

  void clearHover() {
    if (_hoverEdge == null && _hoverCell == null) {
      return;
    }
    _hoverEdge = null;
    _hoverCell = null;
    notifyListeners();
  }

  int? clueAt(int x, int y) => _clues[Point<int>(x, y)];

  int suggestNextClueNumber() => EditorValidator.suggestNextClueNumber(_clues);

  void resize({required int width, required int height}) {
    if (width == _width && height == _height) {
      return;
    }
    final nextHWalls = List.generate(
      height + 1,
      (_) => List<bool>.filled(width, false),
      growable: false,
    );
    final nextVWalls = List.generate(
      height,
      (_) => List<bool>.filled(width + 1, false),
      growable: false,
    );

    final minWidth = min(_width, width);
    final minHeight = min(_height, height);
    for (var y = 0; y <= minHeight; y++) {
      for (var x = 0; x < minWidth; x++) {
        nextHWalls[y][x] = _hWalls[y][x];
      }
    }
    for (var y = 0; y < minHeight; y++) {
      for (var x = 0; x <= minWidth; x++) {
        nextVWalls[y][x] = _vWalls[y][x];
      }
    }

    _clues.removeWhere((point, _) => point.x >= width || point.y >= height);
    _width = width;
    _height = height;
    _hWalls = nextHWalls;
    _vWalls = nextVWalls;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void execute(EditorCommand command) {
    command.apply(this);
    _undoStack.add(command);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final command = _undoStack.removeLast();
    command.revert(this);
    _redoStack.add(command);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final command = _redoStack.removeLast();
    command.apply(this);
    _undoStack.add(command);
    notifyListeners();
  }

  void clear() {
    if (_isEmpty()) {
      return;
    }
    execute(
      ClearCommand(
        hWallsBefore: copyHWallsRaw(),
        vWallsBefore: copyVWallsRaw(),
        cluesBefore: copyCluesRaw(),
      ),
    );
  }

  bool toggleWall(GridEdge edge, {bool? value}) {
    final current = edge.type == EdgeType.horizontal
        ? hasHorizontalWallRaw(edge.x, edge.y)
        : hasVerticalWallRaw(edge.x, edge.y);
    final next = value ?? !current;
    if (next == current) {
      return false;
    }
    execute(
      ToggleWallCommand(
        edge: edge,
        before: current,
        after: next,
      ),
    );
    return true;
  }

  bool setClue(int x, int y, int? value) {
    final current = clueAtRaw(x, y);
    if (current == value) {
      return false;
    }
    if (value == null) {
      execute(RemoveClueCommand(x: x, y: y, before: current));
      return true;
    }
    execute(SetClueCommand(x: x, y: y, before: current, after: value));
    return true;
  }

  EditorLevelData toLevelData() {
    return EditorLevelData(
      width: _width,
      height: _height,
      hWalls: copyHWallsRaw(),
      vWalls: copyVWallsRaw(),
      clues: copyCluesRaw(),
    );
  }

  void loadLevelData(EditorLevelData data) {
    _width = data.width;
    _height = data.height;
    _hWalls =
        data.hWalls.map((row) => List<bool>.from(row)).toList(growable: false);
    _vWalls =
        data.vWalls.map((row) => List<bool>.from(row)).toList(growable: false);
    _clues
      ..clear()
      ..addAll(data.clues);
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  bool _isEmpty() {
    for (final row in _hWalls) {
      if (row.any((value) => value)) {
        return false;
      }
    }
    for (final row in _vWalls) {
      if (row.any((value) => value)) {
        return false;
      }
    }
    return _clues.isEmpty;
  }

  @override
  bool hasHorizontalWallRaw(int x, int y) => _hWalls[y][x];

  @override
  bool hasVerticalWallRaw(int x, int y) => _vWalls[y][x];

  @override
  void setHorizontalWallRaw(int x, int y, bool value) {
    _hWalls[y][x] = value;
  }

  @override
  void setVerticalWallRaw(int x, int y, bool value) {
    _vWalls[y][x] = value;
  }

  @override
  int? clueAtRaw(int x, int y) => _clues[Point<int>(x, y)];

  @override
  void setClueRaw(int x, int y, int? value) {
    final point = Point<int>(x, y);
    if (value == null) {
      _clues.remove(point);
      return;
    }
    _clues[point] = value;
  }

  @override
  List<List<bool>> copyHWallsRaw() {
    return _hWalls.map((row) => List<bool>.from(row)).toList(growable: false);
  }

  @override
  List<List<bool>> copyVWallsRaw() {
    return _vWalls.map((row) => List<bool>.from(row)).toList(growable: false);
  }

  @override
  Map<Point<int>, int> copyCluesRaw() => Map<Point<int>, int>.from(_clues);

  @override
  void restoreSnapshotRaw({
    required List<List<bool>> hWalls,
    required List<List<bool>> vWalls,
    required Map<Point<int>, int> clues,
  }) {
    _hWalls = hWalls.map((row) => List<bool>.from(row)).toList(growable: false);
    _vWalls = vWalls.map((row) => List<bool>.from(row)).toList(growable: false);
    _clues
      ..clear()
      ..addAll(clues);
  }
}
