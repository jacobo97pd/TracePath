import 'dart:math';

abstract class EditorMutator {
  int get width;

  int get height;

  bool hasHorizontalWallRaw(int x, int y);

  bool hasVerticalWallRaw(int x, int y);

  void setHorizontalWallRaw(int x, int y, bool value);

  void setVerticalWallRaw(int x, int y, bool value);

  int? clueAtRaw(int x, int y);

  void setClueRaw(int x, int y, int? value);

  List<List<bool>> copyHWallsRaw();

  List<List<bool>> copyVWallsRaw();

  Map<Point<int>, int> copyCluesRaw();

  void restoreSnapshotRaw({
    required List<List<bool>> hWalls,
    required List<List<bool>> vWalls,
    required Map<Point<int>, int> clues,
  });
}

enum EdgeType {
  horizontal,
  vertical,
}

class GridEdge {
  const GridEdge({
    required this.type,
    required this.x,
    required this.y,
  });

  final EdgeType type;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GridEdge &&
        other.type == type &&
        other.x == x &&
        other.y == y;
  }

  @override
  int get hashCode => Object.hash(type, x, y);
}

abstract class EditorCommand {
  const EditorCommand();

  void apply(EditorMutator state);

  void revert(EditorMutator state);
}

class ToggleWallCommand extends EditorCommand {
  const ToggleWallCommand({
    required this.edge,
    required this.before,
    required this.after,
  });

  final GridEdge edge;
  final bool before;
  final bool after;

  @override
  void apply(EditorMutator state) => _set(state, after);

  @override
  void revert(EditorMutator state) => _set(state, before);

  void _set(EditorMutator state, bool value) {
    if (edge.type == EdgeType.horizontal) {
      state.setHorizontalWallRaw(edge.x, edge.y, value);
      return;
    }
    state.setVerticalWallRaw(edge.x, edge.y, value);
  }
}

class SetClueCommand extends EditorCommand {
  const SetClueCommand({
    required this.x,
    required this.y,
    required this.before,
    required this.after,
  });

  final int x;
  final int y;
  final int? before;
  final int? after;

  @override
  void apply(EditorMutator state) {
    state.setClueRaw(x, y, after);
  }

  @override
  void revert(EditorMutator state) {
    state.setClueRaw(x, y, before);
  }
}

class RemoveClueCommand extends SetClueCommand {
  const RemoveClueCommand({
    required super.x,
    required super.y,
    required super.before,
  }) : super(after: null);
}

class BatchCommand extends EditorCommand {
  const BatchCommand(this.commands);

  final List<EditorCommand> commands;

  @override
  void apply(EditorMutator state) {
    for (final command in commands) {
      command.apply(state);
    }
  }

  @override
  void revert(EditorMutator state) {
    for (var i = commands.length - 1; i >= 0; i--) {
      commands[i].revert(state);
    }
  }
}

class ClearCommand extends EditorCommand {
  ClearCommand({
    required this.hWallsBefore,
    required this.vWallsBefore,
    required this.cluesBefore,
  });

  final List<List<bool>> hWallsBefore;
  final List<List<bool>> vWallsBefore;
  final Map<Point<int>, int> cluesBefore;

  @override
  void apply(EditorMutator state) {
    final hWalls = List.generate(
      state.height + 1,
      (_) => List<bool>.filled(state.width, false),
      growable: false,
    );
    final vWalls = List.generate(
      state.height,
      (_) => List<bool>.filled(state.width + 1, false),
      growable: false,
    );
    state.restoreSnapshotRaw(
      hWalls: hWalls,
      vWalls: vWalls,
      clues: <Point<int>, int>{},
    );
  }

  @override
  void revert(EditorMutator state) {
    state.restoreSnapshotRaw(
      hWalls: hWallsBefore,
      vWalls: vWallsBefore,
      clues: cluesBefore,
    );
  }
}
