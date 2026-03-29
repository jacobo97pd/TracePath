import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'engine/level.dart';
import 'game_theme.dart';
import 'trail/trail_catalog.dart';
import 'trail/comic_spiderverse_trail_rebuilt.dart';
import 'trail/comic_spiderverse_trail_v2.dart';
import 'trail/galaxy_reveal_trail.dart';
import 'trail/trail_renderer.dart';
import 'trail/trail_skin.dart';
import 'trail/urban_graffiti_trail.dart';
import 'ui/components/network_image_compat.dart';

const bool kEnableSolvedDebugLogs = true;
// ignore: constant_identifier_names
const double PATH_WIDTH_RATIO = 0.85;
const String kComicSpiderverseTrailBoardBackgroundAsset =
    'assets/trails/comic_spiderverse/fondo_pantalla_trail_spiderverse.png';
// Safety switch: set to `true` to disable GalaxyReveal and render classic board-color trail.
const bool kGalaxyRevealRollbackToBoardColor = false;

class GameBoardController extends ChangeNotifier {
  _GameBoardState? _state;

  void _attach(_GameBoardState state) {
    _state = state;
  }

  void _detach(_GameBoardState state) {
    if (_state == state) {
      _state = null;
    }
  }

  void reset() {
    _state?._resetPath();
  }

  void undo() {
    _state?._undoLastStep();
  }
}

enum GameBoardChangeType {
  add,
  backtrack,
  rewind,
  reset,
  undo,
}

enum HintDirection {
  none,
  up,
  down,
  left,
  right,
}

class GameBoardChange {
  const GameBoardChange({
    required this.type,
    required this.path,
    required this.affectedCells,
  });

  final GameBoardChangeType type;
  final List<int> path;
  final List<int> affectedCells;
}

class GameBoardStatus {
  const GameBoardStatus({
    required this.path,
    required this.nextRequiredNumber,
    required this.lastSequentialNumber,
    required this.maxNumber,
    required this.solved,
  });

  final List<int> path;
  final int nextRequiredNumber;
  final int lastSequentialNumber;
  final int maxNumber;
  final bool solved;

  factory GameBoardStatus.fromPath(Level level, List<int> path) {
    final maxNumber =
        level.numbers.values.isEmpty ? 0 : level.numbers.values.reduce(max);
    final lastSequentialNumber = GameBoardRules.computeLastSequentialNumber(
      level,
      path,
    );

    return GameBoardStatus(
      path: List<int>.unmodifiable(path),
      nextRequiredNumber: lastSequentialNumber + 1,
      lastSequentialNumber: lastSequentialNumber,
      maxNumber: maxNumber,
      solved: GameBoardRules.computeSolved(level, path),
    );
  }
}

class GameBoardRules {
  const GameBoardRules._();

  static Set<String> buildWallEdges(List<Wall> walls) {
    return walls.map((wall) => edgeKey(wall.cell1, wall.cell2)).toSet();
  }

  static String edgeKey(int a, int b) {
    final first = min(a, b);
    final second = max(a, b);
    return '$first:$second';
  }

  static bool isOrthogonalNeighbor(Level level, int a, int b) {
    final aRow = a ~/ level.width;
    final aCol = a % level.width;
    final bRow = b ~/ level.width;
    final bCol = b % level.width;
    return (aRow - bRow).abs() + (aCol - bCol).abs() == 1;
  }

  static int? startCell(Level level) {
    for (final entry in level.numbers.entries) {
      if (entry.value == 1) {
        return entry.key;
      }
    }
    return null;
  }

  static bool canStartAt(Level level, int cell) {
    final requiredStart = startCell(level);
    return requiredStart == null || requiredStart == cell;
  }

  static bool canMoveToCell(
    Level level,
    List<int> path,
    Set<String> wallEdges,
    int nextCell,
  ) {
    if (path.isEmpty) {
      return canStartAt(level, nextCell);
    }

    final lastCell = path.last;
    if (nextCell == lastCell) {
      return false;
    }

    if (path.contains(nextCell)) {
      return false;
    }

    if (!isOrthogonalNeighbor(level, lastCell, nextCell)) {
      return false;
    }

    if (wallEdges.contains(edgeKey(lastCell, nextCell))) {
      return false;
    }

    return true;
  }

  static bool canBacktrackToPrevious(List<int> path, int cell) {
    return path.length >= 2 && path[path.length - 2] == cell;
  }

  static int computeLastSequentialNumber(Level level, List<int> path) {
    var next = 1;

    for (final cell in path) {
      final number = level.numbers[cell];
      if (number == next) {
        next++;
      }
    }

    return next - 1;
  }

  static int? maxNumber(Level level) {
    if (level.numbers.isEmpty) {
      return null;
    }
    return level.numbers.values.reduce(max);
  }

  static int? endCell(Level level) {
    final maxNum = maxNumber(level);
    if (maxNum == null) {
      return null;
    }
    for (final entry in level.numbers.entries) {
      if (entry.value == maxNum) {
        return entry.key;
      }
    }
    return null;
  }

  static bool computeSolved(Level level, List<int> path) {
    if (path.isEmpty) {
      return false;
    }

    final totalCells = level.width * level.height;
    final visitedAll = path.length == totalCells;
    final noDuplicates = path.toSet().length == path.length;
    final solvedPathOk = visitedAll && noDuplicates;
    final maxNumber = GameBoardRules.maxNumber(level) ?? 0;
    final endCell = GameBoardRules.endCell(level);
    final lastSequentialNumber = computeLastSequentialNumber(level, path);
    final solvedNumbersOk = lastSequentialNumber == maxNumber;
    final endsAtFinalNumberCell = endCell == null || path.last == endCell;

    return solvedPathOk && solvedNumbersOk && endsAtFinalNumberCell;
  }

  static List<int> numberedCellsEncounteredInPath(Level level, List<int> path) {
    final encountered = <int>[];
    for (final cell in path) {
      final number = level.numbers[cell];
      if (number != null) {
        encountered.add(number);
      }
    }
    return encountered;
  }

  static Map<String, Object> solvedDebugData(Level level, List<int> path) {
    final totalCells = level.width * level.height;
    final noDuplicates = path.toSet().length == path.length;
    final maxNumber =
        level.numbers.values.isEmpty ? 0 : level.numbers.values.reduce(max);
    final lastSequentialNumber = computeLastSequentialNumber(level, path);
    final encountered = numberedCellsEncounteredInPath(level, path);

    return <String, Object>{
      'totalCells': totalCells,
      'pathLength': path.length,
      'noDuplicates': noDuplicates,
      'maxNumber': maxNumber,
      'lastSequentialNumber': lastSequentialNumber,
      'encounteredNumbers': encountered,
    };
  }
}

class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.level,
    required this.gameTheme,
    this.pathColorOverride,
    this.trailSkin = TrailCatalog.classic,
    this.pointerAssetPath,
    this.hintDirection = HintDirection.none,
    this.hintVisible = false,
    this.controller,
    this.onCellAdded,
    this.onPathChanged,
    this.onStatusChanged,
    this.onInvalidMove,
    this.onChange,
    this.initialPath = const <int>[],
    this.opponentPath = const <int>[],
    this.opponentTrailColor,
    this.isInteractionLocked = false,
  });

  final Level level;
  final GameTheme gameTheme;
  final Color? pathColorOverride;
  final TrailSkinConfig trailSkin;
  final String? pointerAssetPath;
  final HintDirection hintDirection;
  final bool hintVisible;
  final GameBoardController? controller;
  final void Function(int cellIndex, List<int> path)? onCellAdded;
  final ValueChanged<List<int>>? onPathChanged;
  final ValueChanged<GameBoardStatus>? onStatusChanged;
  final ValueChanged<String>? onInvalidMove;
  final ValueChanged<GameBoardChange>? onChange;
  final List<int> initialPath;
  final List<int> opponentPath;
  final Color? opponentTrailColor;
  final bool isInteractionLocked;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  final List<int> _path = <int>[];
  late final AnimationController _transitionController;
  late final AnimationController _hintController;
  late final AnimationController _trailVfxController;
  late Set<String> _wallEdges;
  Timer? _errorTimer;
  Timer? _resumeHighlightTimer;
  bool _showErrorFlash = false;
  int? _highlightedResumeCell;
  List<int> _appearingCells = const <int>[];
  List<int> _disappearingCells = const <int>[];
  HintDirection _paintHintDirection = HintDirection.none;
  int? _paintHintSourceCell;
  int? _lastDragCell;
  ui.Image? _pointerImage;
  String? _loadedPointerAssetPath;
  final Set<String> _webPointerStartedPaths = <String>{};
  final Set<String> _webPointerLoadedPaths = <String>{};
  final Set<String> _webPointerFailedPaths = <String>{};
  List<ui.Image> _smokePuffImages = const <ui.Image>[];
  bool _smokeAssetsLoaded = false;
  List<ui.Image> _punkIconImages = const <ui.Image>[];
  bool _punkIconsLoaded = false;
  WebTrailSprites _webTrailSprites = const WebTrailSprites();
  bool _webTrailAssetsLoaded = false;
  WebLegendaryTrailSprites _webLegendaryTrailSprites =
      const WebLegendaryTrailSprites();
  bool _webLegendaryTrailAssetsLoaded = false;
  ComicSpiderverseTrailSprites _comicSpiderverseTrailSprites =
      const ComicSpiderverseTrailSprites();
  bool _comicSpiderverseAssetsLoaded = false;
  ComicSpiderverseRebuiltSprites _comicSpiderverseRebuiltTrailSprites =
      const ComicSpiderverseRebuiltSprites();
  bool _comicSpiderverseRebuiltAssetsLoaded = false;
  UrbanGraffitiTrailSprites _urbanGraffitiTrailSprites =
      const UrbanGraffitiTrailSprites();
  bool _urbanGraffitiAssetsLoaded = false;
  bool _didVerifyUrbanGraffitiAssets = false;
  ui.Image? _comicSpiderverseBoardBackground;
  bool _comicSpiderverseBoardBackgroundLoaded = false;
  final GalaxyRevealTrailController _galaxyRevealController =
      GalaxyRevealTrailController();
  ui.Image? _galaxyRevealTexture;
  bool _galaxyRevealTextureLoaded = false;
  String? _galaxyRevealTextureAssetPathLoaded;
  bool _didVerifyComicSpiderverseRebuiltAssets = false;
  List<_ComicSnapshotState> _comicSnapshots = const <_ComicSnapshotState>[];
  int _comicVisualFrame = 0;
  int _lastComicStepMs = 0;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..value = 1;
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..value = 0;
    _trailVfxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _trailVfxController.addListener(_handleTrailTick);
    _hintController.addStatusListener(_handleHintAnimationStatus);
    _wallEdges = GameBoardRules.buildWallEdges(widget.level.walls);
    _applyInitialPath();
    _syncPointerSkin();
    _syncSmokeAssets(force: true);
    _syncPunkIconAssets(force: true);
    _syncWebTrailAssets(force: true);
    _syncWebLegendaryTrailAssets(force: true);
    _syncComicSpiderverseAssets(force: true);
    _verifyComicSpiderverseRebuiltAssetSetOnce();
    _syncComicSpiderverseRebuiltAssets(force: true);
    _verifyUrbanGraffitiAssetSetOnce();
    _syncUrbanGraffitiAssets(force: true);
    _syncComicSpiderverseBoardBackground(force: true);
    _syncGalaxyRevealTexture(force: true);
    _syncGalaxyRevealProgressFromPath(forceRebuild: true);
    widget.controller?._attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emitPathState();
      }
    });
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.level != widget.level) {
      _wallEdges = GameBoardRules.buildWallEdges(widget.level.walls);
      _clearTransientState();
      _path.clear();
      _resetAnimationState();
      _paintHintDirection = HintDirection.none;
      _paintHintSourceCell = null;
      _hintController.value = 0;
      _applyInitialPath();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _emitPathState();
        }
      });
    } else if (!listEquals(oldWidget.initialPath, widget.initialPath)) {
      _applyInitialPath();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _emitPathState();
        }
      });
    }
    if (oldWidget.pointerAssetPath != widget.pointerAssetPath) {
      _syncPointerSkin();
    }
    if (oldWidget.trailSkin.id != widget.trailSkin.id) {
      _syncSmokeAssets();
      _syncPunkIconAssets();
      _syncWebTrailAssets();
      _syncWebLegendaryTrailAssets();
      _syncComicSpiderverseAssets();
      _syncComicSpiderverseRebuiltAssets();
      _syncUrbanGraffitiAssets();
      _syncComicSpiderverseBoardBackground();
      _syncGalaxyRevealTexture();
      _syncGalaxyRevealProgressFromPath(forceRebuild: true);
    }
    if (oldWidget.trailSkin.id != widget.trailSkin.id &&
        widget.trailSkin.renderType != TrailRenderType.comic) {
      _comicSnapshots = const <_ComicSnapshotState>[];
      _comicVisualFrame = 0;
      _lastComicStepMs = 0;
    }
    if (oldWidget.level != widget.level) {
      _syncGalaxyRevealProgressFromPath(forceRebuild: true);
    }
    _syncHintVisualState(oldWidget);
  }

  Future<void> _syncSmokeAssets({bool force = false}) async {
    final needsSmoke = widget.trailSkin.renderType == TrailRenderType.smoke;
    if (!needsSmoke) {
      if (_smokePuffImages.isNotEmpty || _smokeAssetsLoaded) {
        setState(() {
          _smokePuffImages = const <ui.Image>[];
          _smokeAssetsLoaded = false;
        });
      }
      return;
    }
    if (_smokeAssetsLoaded && !force) return;
    const smokeAssets = <String>[
      'assets/vfx/smoke/smoke_puff_1.png',
      'assets/vfx/smoke/smoke_puff_2.png',
      'assets/vfx/smoke/smoke_puff_3.png',
    ];
    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}
    final loaded = <ui.Image>[];
    for (final assetPath in smokeAssets) {
      final manifestMiss =
          manifestKeys != null && !manifestKeys.contains(assetPath);
      try {
        final bytes = await rootBundle.load(assetPath);
        final img = await decodeImageFromList(bytes.buffer.asUint8List());
        if (manifestMiss) {
          debugPrint(
              '[TrailAssets][smoke] manifest miss but load OK: $assetPath');
        }
        loaded.add(img);
      } catch (e) {
        debugPrint('[TrailAssets][smoke] load fail $assetPath -> $e');
      }
    }
    if (!mounted) return;
    debugPrint(
        '[TrailAssets][smoke] loaded ${loaded.length}/${smokeAssets.length}');
    setState(() {
      _smokePuffImages = List<ui.Image>.unmodifiable(loaded);
      _smokeAssetsLoaded = true;
    });
  }

  Future<void> _syncPunkIconAssets({bool force = false}) async {
    final needsIcons = widget.trailSkin.renderType == TrailRenderType.punkRiff;
    if (!needsIcons) {
      if (_punkIconImages.isNotEmpty || _punkIconsLoaded) {
        setState(() {
          _punkIconImages = const <ui.Image>[];
          _punkIconsLoaded = false;
        });
      }
      return;
    }
    if (_punkIconsLoaded && !force) return;

    const iconAssets = <String>[
      'assets/icons/guitarra_electrica_animada.ico',
      'assets/icons/pua_animada.ico',
      'assets/shop/icons/guitarra_electrica_animada.ico',
      'assets/shop/icons/pua_animada.ico',
    ];
    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}

    final loaded = <ui.Image>[];
    for (final assetPath in iconAssets) {
      final manifestMiss =
          manifestKeys != null && !manifestKeys.contains(assetPath);
      try {
        final bytes = await rootBundle.load(assetPath);
        final raw = bytes.buffer.asUint8List();
        ui.Image? decoded;
        try {
          decoded = await decodeImageFromList(raw);
        } catch (_) {
          decoded = null;
        }

        if (decoded == null) {
          final fallback = img.decodeImage(raw);
          if (fallback != null) {
            final png = img.encodePng(fallback);
            final codec = await ui.instantiateImageCodec(
              Uint8List.fromList(png),
            );
            final frame = await codec.getNextFrame();
            decoded = frame.image;
          }
        }

        if (decoded != null) {
          if (manifestMiss) {
            debugPrint(
              '[TrailAssets][punk_icons] manifest miss but load OK: $assetPath',
            );
          }
          loaded.add(decoded);
        }
      } catch (e) {
        debugPrint('[TrailAssets][punk_icons] load fail $assetPath -> $e');
      }
    }
    if (!mounted) return;
    debugPrint(
        '[TrailAssets][punk_icons] loaded ${loaded.length}/${iconAssets.length}');
    setState(() {
      _punkIconImages = List<ui.Image>.unmodifiable(loaded);
      _punkIconsLoaded = true;
    });
  }

  Future<void> _syncWebTrailAssets({bool force = false}) async {
    final needsWeb = widget.trailSkin.renderType == TrailRenderType.web;
    if (!needsWeb) {
      if (_webTrailAssetsLoaded) {
        setState(() {
          _webTrailSprites = const WebTrailSprites();
          _webTrailAssetsLoaded = false;
        });
      }
      return;
    }
    if (_webTrailAssetsLoaded && !force) return;

    const preferred = <String, String>{
      'nodeBurst01': 'assets/trails/web_node_burst_01.png',
      'nodeBurst02': 'assets/trails/web_node_burst_02.png',
      // Reuse legendary assets as WebTrail sprite pack source.
      'sparkle': 'assets/trails/web_trail_legendary/web_legendary_sparkle.png',
      'microBridge':
          'assets/trails/web_trail_legendary/web_legendary_micro_bridge.png',
      'threadSoft':
          'assets/trails/web_trail_legendary/web_legendary_highlight_streak.png',
      'silkFragment':
          'assets/trails/web_trail_legendary/web_legendary_energy_flick.png',
      'highlightStreak':
          'assets/trails/web_trail_legendary/web_legendary_highlight_streak.png',
    };
    const fallback = <String, String>{
      'nodeBurst01': 'assets/trails/web_node_burst_01.png',
      'nodeBurst02': 'assets/trails/web_node_burst_02.png',
    };

    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}

    Future<ui.Image?> loadNamed(String key) async {
      final candidates = <String>[
        if (preferred.containsKey(key)) preferred[key]!,
        if (fallback.containsKey(key)) fallback[key]!,
      ];
      for (final assetPath in candidates) {
        final manifestMiss =
            manifestKeys != null && !manifestKeys.contains(assetPath);
        try {
          final bytes = await rootBundle.load(assetPath);
          if (manifestMiss) {
            debugPrint(
              '[TrailAssets][web] manifest miss but load OK: $assetPath',
            );
          }
          return decodeImageFromList(bytes.buffer.asUint8List());
        } catch (e) {
          debugPrint('[TrailAssets][web] load fail $assetPath -> $e');
        }
      }
      return null;
    }

    final nodeBurst01 = await loadNamed('nodeBurst01');
    final nodeBurst02 = await loadNamed('nodeBurst02');
    final sparkle = await loadNamed('sparkle');
    final microBridge = await loadNamed('microBridge');
    final threadSoft = await loadNamed('threadSoft');
    final silkFragment = await loadNamed('silkFragment');
    final highlightStreak = await loadNamed('highlightStreak');

    if (!mounted) return;
    final loadedCount = <ui.Image?>[
      nodeBurst01,
      nodeBurst02,
      sparkle,
      microBridge,
      threadSoft,
      silkFragment,
      highlightStreak,
    ].where((img) => img != null).length;
    debugPrint('[TrailAssets][web] loaded $loadedCount/7');
    setState(() {
      _webTrailSprites = WebTrailSprites(
        nodeBurst01: nodeBurst01,
        nodeBurst02: nodeBurst02,
        sparkle: sparkle,
        microBridge: microBridge,
        threadSoft: threadSoft,
        silkFragment: silkFragment,
        highlightStreak: highlightStreak,
      );
      _webTrailAssetsLoaded = true;
    });
  }

  Future<void> _syncWebLegendaryTrailAssets({bool force = false}) async {
    final needsLegendary =
        widget.trailSkin.renderType == TrailRenderType.webLegendary;
    if (!needsLegendary) {
      if (_webLegendaryTrailAssetsLoaded) {
        setState(() {
          _webLegendaryTrailSprites = const WebLegendaryTrailSprites();
          _webLegendaryTrailAssetsLoaded = false;
        });
      }
      return;
    }
    if (_webLegendaryTrailAssetsLoaded && !force) return;

    const preferred = <String, String>{
      'nodeBurst01':
          'assets/trails/web_trail_legendary/web_legendary_node_burst_01.png',
      'nodeBurst02':
          'assets/trails/web_trail_legendary/web_legendary_node_burst_02.png',
      'sparkle': 'assets/trails/web_trail_legendary/web_legendary_sparkle.png',
      'energyFlick':
          'assets/trails/web_trail_legendary/web_legendary_energy_flick.png',
      'microBridge':
          'assets/trails/web_trail_legendary/web_legendary_micro_bridge.png',
      'highlightStreak':
          'assets/trails/web_trail_legendary/web_legendary_highlight_streak.png',
      'halftonePatch':
          'assets/trails/web_trail_legendary/web_legendary_halftone_patch.png',
    };

    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}

    Future<ui.Image?> loadNamed(String key) async {
      final assetPath = preferred[key];
      if (assetPath == null) return null;
      final manifestMiss =
          manifestKeys != null && !manifestKeys.contains(assetPath);
      try {
        final bytes = await rootBundle.load(assetPath);
        if (manifestMiss) {
          debugPrint(
            '[TrailAssets][web_legendary] manifest miss but load OK: $assetPath',
          );
        }
        return decodeImageFromList(bytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('[TrailAssets][web_legendary] load fail $assetPath -> $e');
        return null;
      }
    }

    final nodeBurst01 = await loadNamed('nodeBurst01');
    final nodeBurst02 = await loadNamed('nodeBurst02');
    final sparkle = await loadNamed('sparkle');
    final energyFlick = await loadNamed('energyFlick');
    final microBridge = await loadNamed('microBridge');
    final highlightStreak = await loadNamed('highlightStreak');
    final halftonePatch = await loadNamed('halftonePatch');

    if (!mounted) return;
    final loadedCount = <ui.Image?>[
      nodeBurst01,
      nodeBurst02,
      sparkle,
      energyFlick,
      microBridge,
      highlightStreak,
      halftonePatch,
    ].where((img) => img != null).length;
    debugPrint('[TrailAssets][web_legendary] loaded $loadedCount/7');
    setState(() {
      _webLegendaryTrailSprites = WebLegendaryTrailSprites(
        nodeBurst01: nodeBurst01,
        nodeBurst02: nodeBurst02,
        sparkle: sparkle,
        energyFlick: energyFlick,
        microBridge: microBridge,
        highlightStreak: highlightStreak,
        halftonePatch: halftonePatch,
      );
      _webLegendaryTrailAssetsLoaded = true;
    });
  }

  Future<void> _syncComicSpiderverseAssets({bool force = false}) async {
    final needs =
        widget.trailSkin.renderType == TrailRenderType.comicSpiderverse ||
            widget.trailSkin.renderType == TrailRenderType.comicSpiderverseV2;
    if (!needs) {
      if (_comicSpiderverseAssetsLoaded) {
        setState(() {
          _comicSpiderverseTrailSprites = const ComicSpiderverseTrailSprites();
          _comicSpiderverseAssetsLoaded = false;
        });
      }
      return;
    }
    if (_comicSpiderverseAssetsLoaded && !force) return;

    const assets = ComicSpiderverseTrailV2.assetPaths;

    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}

    Future<ui.Image?> loadNamed(String key) async {
      final assetPath = assets[key];
      if (assetPath == null) return null;
      final manifestMiss =
          manifestKeys != null && !manifestKeys.contains(assetPath);
      try {
        final bytes = await rootBundle.load(assetPath);
        if (manifestMiss) {
          debugPrint(
            '[TrailAssets][comic_spiderverse] manifest miss but load OK: $assetPath',
          );
        }
        return decodeImageFromList(bytes.buffer.asUint8List());
      } catch (e) {
        debugPrint(
            '[TrailAssets][comic_spiderverse] load fail $assetPath -> $e');
        return null;
      }
    }

    final glitchStreak = await loadNamed('glitchStreak');
    final offsetShadow = await loadNamed('offsetShadow');
    final frameSlice = await loadNamed('frameSlice');
    final dotParticle = await loadNamed('dotParticle');
    final starParticle = await loadNamed('starParticle');
    final burst01 = await loadNamed('burst01');
    final burst02 = await loadNamed('burst02');
    final inkSplash01 = await loadNamed('inkSplash01');
    final inkSplash02 = await loadNamed('inkSplash02');
    final halftone01 = await loadNamed('halftone01');
    final halftone02 = await loadNamed('halftone02');
    final bubble01 = await loadNamed('bubble01');
    final bubble02 = await loadNamed('bubble02');
    final textPow = await loadNamed('textPow');
    final textBzz = await loadNamed('textBzz');

    if (!mounted) return;
    final loadedCount = <ui.Image?>[
      glitchStreak,
      offsetShadow,
      frameSlice,
      dotParticle,
      starParticle,
      burst01,
      burst02,
      inkSplash01,
      inkSplash02,
      halftone01,
      halftone02,
      bubble01,
      bubble02,
      textPow,
      textBzz,
    ].where((img) => img != null).length;
    debugPrint('[TrailAssets][comic_spiderverse] loaded $loadedCount/15');
    setState(() {
      _comicSpiderverseTrailSprites = ComicSpiderverseTrailSprites(
        glitchStreak: glitchStreak,
        offsetShadow: offsetShadow,
        frameSlice: frameSlice,
        dotParticle: dotParticle,
        starParticle: starParticle,
        burst01: burst01,
        burst02: burst02,
        inkSplash01: inkSplash01,
        inkSplash02: inkSplash02,
        halftone01: halftone01,
        halftone02: halftone02,
        bubble01: bubble01,
        bubble02: bubble02,
        textPow: textPow,
        textBzz: textBzz,
      );
      _comicSpiderverseAssetsLoaded = true;
    });
  }

  Future<void> _verifyComicSpiderverseRebuiltAssetSetOnce() async {
    if (_didVerifyComicSpiderverseRebuiltAssets) return;
    _didVerifyComicSpiderverseRebuiltAssets = true;
    const assets = ComicSpiderverseTrailRebuilt.assetPaths;
    for (final key in ComicSpiderverseTrailRebuilt.requiredAssetKeys) {
      final assetPath = assets[key];
      final fileName = assetPath?.split('/').last ?? key;
      if (assetPath == null) {
        debugPrint(
          '[TrailAssets][comic_spiderverse_rebuilt] [MISSING] $fileName',
        );
        continue;
      }
      try {
        final bytes = await rootBundle.load(assetPath);
        await decodeImageFromList(bytes.buffer.asUint8List());
        debugPrint(
          '[TrailAssets][comic_spiderverse_rebuilt] [OK] $fileName loaded',
        );
      } catch (e) {
        debugPrint(
          '[TrailAssets][comic_spiderverse_rebuilt] [MISSING] $fileName -> $e',
        );
      }
    }
  }

  Future<void> _syncComicSpiderverseRebuiltAssets({bool force = false}) async {
    final needs =
        widget.trailSkin.renderType == TrailRenderType.comicSpiderverseRebuilt;
    if (!needs) {
      if (_comicSpiderverseRebuiltAssetsLoaded) {
        setState(() {
          _comicSpiderverseRebuiltTrailSprites =
              const ComicSpiderverseRebuiltSprites();
          _comicSpiderverseRebuiltAssetsLoaded = false;
        });
      }
      return;
    }
    if (_comicSpiderverseRebuiltAssetsLoaded && !force) return;

    const assets = ComicSpiderverseTrailRebuilt.assetPaths;
    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}

    final loadedByKey = <String, ui.Image?>{};
    for (final key in ComicSpiderverseTrailRebuilt.requiredAssetKeys) {
      final assetPath = assets[key];
      if (assetPath == null) {
        debugPrint(
            '[TrailAssets][comic_spiderverse_rebuilt] [MISSING] $key (no path)');
        loadedByKey[key] = null;
        continue;
      }
      final fileName = assetPath.split('/').last;
      final inManifest =
          manifestKeys == null || manifestKeys.contains(assetPath);
      try {
        final bytes = await rootBundle.load(assetPath);
        final image = await decodeImageFromList(bytes.buffer.asUint8List());
        loadedByKey[key] = image;
        final suffix = inManifest ? '' : ' (manifest miss, load OK)';
        debugPrint(
          '[TrailAssets][comic_spiderverse_rebuilt] [OK] $fileName loaded$suffix',
        );
      } catch (e) {
        loadedByKey[key] = null;
        debugPrint(
          '[TrailAssets][comic_spiderverse_rebuilt] [MISSING] $fileName -> $e',
        );
      }
    }

    if (!mounted) return;
    final loadedCount = loadedByKey.values.where((img) => img != null).length;
    debugPrint(
      '[TrailAssets][comic_spiderverse_rebuilt] summary loaded $loadedCount/${ComicSpiderverseTrailRebuilt.requiredAssetKeys.length}',
    );
    setState(() {
      _comicSpiderverseRebuiltTrailSprites = ComicSpiderverseRebuiltSprites(
        glitchStreak: loadedByKey['glitchStreak'],
        offsetShadow: loadedByKey['offsetShadow'],
        frameSlice: loadedByKey['frameSlice'],
        dotParticle: loadedByKey['dotParticle'],
        starParticle: loadedByKey['starParticle'],
        burst01: loadedByKey['burst01'],
        burst02: loadedByKey['burst02'],
        inkSplash01: loadedByKey['inkSplash01'],
        inkSplash02: loadedByKey['inkSplash02'],
        halftone01: loadedByKey['halftone01'],
        halftone02: loadedByKey['halftone02'],
        bubble01: loadedByKey['bubble01'],
        bubble02: loadedByKey['bubble02'],
        textPow: loadedByKey['textPow'],
        textBzz: loadedByKey['textBzz'],
      );
      _comicSpiderverseRebuiltAssetsLoaded = true;
    });
  }

  Future<void> _verifyUrbanGraffitiAssetSetOnce() async {
    if (_didVerifyUrbanGraffitiAssets) return;
    _didVerifyUrbanGraffitiAssets = true;
    const assets = UrbanGraffitiTrail.assetPaths;
    for (final key in UrbanGraffitiTrail.requiredAssetKeys) {
      final assetPath = assets[key];
      final fileName = assetPath?.split('/').last ?? key;
      if (assetPath == null) {
        debugPrint('[TrailAssets][urban_graffiti] [MISSING] $fileName');
        continue;
      }
      try {
        final bytes = await rootBundle.load(assetPath);
        await decodeImageFromList(bytes.buffer.asUint8List());
        debugPrint('[TrailAssets][urban_graffiti] [OK] $fileName loaded');
      } catch (e) {
        debugPrint('[TrailAssets][urban_graffiti] [MISSING] $fileName -> $e');
      }
    }
  }

  Future<void> _syncUrbanGraffitiAssets({bool force = false}) async {
    final needs = widget.trailSkin.renderType == TrailRenderType.urbanGraffiti;
    if (!needs) {
      if (_urbanGraffitiAssetsLoaded) {
        setState(() {
          _urbanGraffitiTrailSprites = const UrbanGraffitiTrailSprites();
          _urbanGraffitiAssetsLoaded = false;
        });
      }
      return;
    }
    if (_urbanGraffitiAssetsLoaded && !force) return;

    await _verifyUrbanGraffitiAssetSetOnce();

    const assets = UrbanGraffitiTrail.assetPaths;
    final loadedByKey = <String, ui.Image?>{};
    for (final key in UrbanGraffitiTrail.requiredAssetKeys) {
      final assetPath = assets[key];
      if (assetPath == null) {
        loadedByKey[key] = null;
        continue;
      }
      try {
        final bytes = await rootBundle.load(assetPath);
        loadedByKey[key] =
            await decodeImageFromList(bytes.buffer.asUint8List());
      } catch (_) {
        loadedByKey[key] = null;
      }
    }

    if (!mounted) return;
    final loadedCount = loadedByKey.values.where((img) => img != null).length;
    debugPrint(
      '[TrailAssets][urban_graffiti] summary loaded $loadedCount/${UrbanGraffitiTrail.requiredAssetKeys.length}',
    );
    setState(() {
      _urbanGraffitiTrailSprites = UrbanGraffitiTrailSprites(
        graffitiSplash: loadedByKey['graffitiSplash'],
        graffitiTag01: loadedByKey['graffitiTag01'],
        paintDrip: loadedByKey['paintDrip'],
        spraySoft: loadedByKey['spraySoft'],
      );
      _urbanGraffitiAssetsLoaded = true;
    });
  }

  bool _isComicSpiderverseTrail(TrailRenderType renderType) {
    return renderType == TrailRenderType.comicSpiderverse ||
        renderType == TrailRenderType.comicSpiderverseV2 ||
        renderType == TrailRenderType.comicSpiderverseRebuilt;
  }

  Future<void> _syncComicSpiderverseBoardBackground(
      {bool force = false}) async {
    final needs = _isComicSpiderverseTrail(widget.trailSkin.renderType);
    if (!needs) {
      if (_comicSpiderverseBoardBackgroundLoaded ||
          _comicSpiderverseBoardBackground != null) {
        setState(() {
          _comicSpiderverseBoardBackground = null;
          _comicSpiderverseBoardBackgroundLoaded = false;
        });
      }
      return;
    }
    if (_comicSpiderverseBoardBackgroundLoaded && !force) return;

    Set<String>? manifestKeys;
    try {
      final rawManifest = await rootBundle.loadString('AssetManifest.json');
      final decoded = jsonDecode(rawManifest);
      if (decoded is Map<String, dynamic>) {
        manifestKeys = decoded.keys.toSet();
      }
    } catch (_) {}

    final manifestMiss = manifestKeys != null &&
        !manifestKeys.contains(kComicSpiderverseTrailBoardBackgroundAsset);
    try {
      final bytes =
          await rootBundle.load(kComicSpiderverseTrailBoardBackgroundAsset);
      final image = await decodeImageFromList(bytes.buffer.asUint8List());
      if (!mounted) return;
      // Guard against async race: if trail changed while loading, do not apply.
      if (!_isComicSpiderverseTrail(widget.trailSkin.renderType)) return;
      if (manifestMiss) {
        debugPrint(
          '[TrailAssets][comic_spiderverse_bg] manifest miss but load OK: $kComicSpiderverseTrailBoardBackgroundAsset',
        );
      } else {
        debugPrint(
          '[TrailAssets][comic_spiderverse_bg] loaded fondo_pantalla_trail_spiderverse.png',
        );
      }
      setState(() {
        _comicSpiderverseBoardBackground = image;
        _comicSpiderverseBoardBackgroundLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint(
        '[TrailAssets][comic_spiderverse_bg] load fail $kComicSpiderverseTrailBoardBackgroundAsset -> $e',
      );
      setState(() {
        _comicSpiderverseBoardBackground = null;
        _comicSpiderverseBoardBackgroundLoaded = false;
      });
    }
  }

  bool get _needsGalaxyRevealTrail =>
      widget.trailSkin.renderType == TrailRenderType.galaxyReveal;

  Future<void> _syncGalaxyRevealTexture({bool force = false}) async {
    if (!_needsGalaxyRevealTrail) {
      if (_galaxyRevealTextureLoaded ||
          _galaxyRevealTexture != null ||
          _galaxyRevealTextureAssetPathLoaded != null) {
        setState(() {
          _galaxyRevealTexture = null;
          _galaxyRevealTextureLoaded = false;
          _galaxyRevealTextureAssetPathLoaded = null;
        });
      }
      return;
    }
    final targetAsset = widget.trailSkin.galaxyReveal.textureAsset;
    if (_galaxyRevealTextureLoaded &&
        !force &&
        _galaxyRevealTextureAssetPathLoaded == targetAsset) {
      return;
    }
    try {
      final bytes = await rootBundle.load(targetAsset);
      final image = await decodeImageFromList(bytes.buffer.asUint8List());
      if (!mounted) return;
      if (!_needsGalaxyRevealTrail) return;
      if (widget.trailSkin.galaxyReveal.textureAsset != targetAsset) return;
      if (kDebugMode) {
        debugPrint(
          'GALAXY IMAGE LOADED: ${image.width}x${image.height} asset=$targetAsset',
        );
      }
      setState(() {
        _galaxyRevealTexture = image;
        _galaxyRevealTextureLoaded = true;
        _galaxyRevealTextureAssetPathLoaded = targetAsset;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint(
        '[TrailAssets][galaxy_reveal] load fail $targetAsset -> $e',
      );
      setState(() {
        _galaxyRevealTexture = null;
        _galaxyRevealTextureLoaded = false;
        _galaxyRevealTextureAssetPathLoaded = null;
      });
    }
  }

  void _syncGalaxyRevealProgressFromPath({bool forceRebuild = false}) {
    if (!_needsGalaxyRevealTrail) {
      _galaxyRevealController.reset();
      return;
    }
    if (!forceRebuild && _path.isEmpty) return;
    final unitPoints =
        _path.map((cell) => _centerForCellUnit(cell)).toList(growable: false);
    _galaxyRevealController.absorbPathUnit(
      unitPoints,
      enableSparkles: widget.trailSkin.galaxyReveal.enableSparkles,
      nowSec: DateTime.now().microsecondsSinceEpoch / 1000000.0,
    );
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _trailVfxController.removeListener(_handleTrailTick);
    _hintController.removeStatusListener(_handleHintAnimationStatus);
    _hintController.dispose();
    _trailVfxController.dispose();
    _transitionController.dispose();
    _errorTimer?.cancel();
    _resumeHighlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cellSize = maxWidth / widget.level.width;
        final boardHeight = cellSize * widget.level.height;
        final status = _currentStatus;
        final hintCell = _paintHintSourceCell;

        return Center(
          child: SizedBox(
            width: maxWidth,
            height: boardHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: widget.isInteractionLocked
                  ? null
                  : (details) => _handleCellTap(
                        _cellIndexForOffset(details.localPosition, maxWidth),
                      ),
              onLongPressStart: widget.isInteractionLocked
                  ? null
                  : (details) => _handleCellTap(
                        _cellIndexForOffset(details.localPosition, maxWidth),
                      ),
              onPanStart: widget.isInteractionLocked
                  ? null
                  : (details) {
                      _lastDragCell = null;
                      _handlePanCell(
                        _cellIndexForOffset(details.localPosition, maxWidth),
                      );
                    },
              onPanUpdate: widget.isInteractionLocked
                  ? null
                  : (details) => _handlePanCell(
                        _cellIndexForOffset(details.localPosition, maxWidth),
                      ),
              onPanEnd: widget.isInteractionLocked
                  ? null
                  : (_) {
                      _lastDragCell = null;
                    },
              child: AnimatedBuilder(
                animation: Listenable.merge(
                  <Listenable>[
                    _transitionController,
                    _hintController,
                    _trailVfxController,
                  ],
                ),
                builder: (context, child) {
                  final overlayPointer = _buildPointerOverlayWidget(cellSize);
                  final overlayHint = _buildHintOverlayWidget(
                    maxWidth: maxWidth,
                    cellSize: cellSize,
                    hintCell: hintCell,
                  );
                  return RepaintBoundary(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _GameBoardPainter(
                            level: widget.level,
                            gameTheme: widget.gameTheme,
                            pathColorOverride: widget.pathColorOverride,
                            trailSkin: widget.trailSkin,
                            trailPhase: _trailVfxController.value,
                            visualPhase: _comicVisualFrame / 12,
                            visualFrame: _comicVisualFrame,
                            comicSnapshots:
                                _buildComicPainterSnapshots(cellSize),
                            pointerImage: _pointerImage,
                            smokePuffImages: _smokePuffImages,
                            punkIconImages: _punkIconImages,
                            webTrailSprites: _webTrailSprites,
                            webLegendaryTrailSprites: _webLegendaryTrailSprites,
                            comicSpiderverseTrailSprites:
                                _comicSpiderverseTrailSprites,
                            comicSpiderverseRebuiltTrailSprites:
                                _comicSpiderverseRebuiltTrailSprites,
                            urbanGraffitiTrailSprites:
                                _urbanGraffitiTrailSprites,
                            galaxyRevealTexture: _galaxyRevealTexture,
                            galaxyRevealController: _galaxyRevealController,
                            comicSpiderverseBoardBackground:
                                _isComicSpiderverseTrail(
                              widget.trailSkin.renderType,
                            )
                                    ? _comicSpiderverseBoardBackground
                                    : null,
                            path: List<int>.unmodifiable(_path),
                            opponentPath:
                                List<int>.unmodifiable(widget.opponentPath),
                            opponentTrailColor: widget.opponentTrailColor,
                            solved: status.solved,
                            hintDirection: HintDirection.none,
                            hintSourceCell: null,
                            hintOpacity: 0,
                            highlightedResumeCell: _highlightedResumeCell,
                            showErrorFlash: _showErrorFlash,
                            appearingCells:
                                List<int>.unmodifiable(_appearingCells),
                            disappearingCells: List<int>.unmodifiable(
                              _disappearingCells,
                            ),
                            transitionValue: _transitionController.value,
                          ),
                        ),
                        if (overlayPointer != null) overlayPointer,
                        if (overlayHint != null) overlayHint,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTrailTick() {
    final steppedVisual =
        widget.trailSkin.renderType == TrailRenderType.comic ||
            widget.trailSkin.renderType == TrailRenderType.comicSpiderverse ||
            widget.trailSkin.renderType == TrailRenderType.comicSpiderverseV2 ||
            widget.trailSkin.renderType ==
                TrailRenderType.comicSpiderverseRebuilt ||
            widget.trailSkin.renderType == TrailRenderType.punkRiff;
    if (!steppedVisual) {
      if (_comicSnapshots.isNotEmpty || _comicVisualFrame != 0) {
        _comicSnapshots = const <_ComicSnapshotState>[];
        _comicVisualFrame = 0;
        _lastComicStepMs = 0;
      }
      return;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    int stepMs = (1000 / widget.trailSkin.visualStepFps).round().clamp(24, 200);
    if (widget.trailSkin.renderType == TrailRenderType.comicSpiderverseV2) {
      final cfg = widget.trailSkin.comicSpiderverseV2;
      final jitterWindow = max(1, cfg.steppedFrameJitter * 2 + 1);
      final jitter =
          ((_comicVisualFrame * 17) % jitterWindow) - cfg.steppedFrameJitter;
      stepMs = (cfg.steppedFrameMs + jitter).clamp(38, 46);
    } else if (widget.trailSkin.renderType ==
        TrailRenderType.comicSpiderverseRebuilt) {
      final cfg = widget.trailSkin.comicSpiderverseRebuilt;
      final jitterWindow = max(1, cfg.steppedFrameJitter * 2 + 1);
      final jitter =
          ((_comicVisualFrame * 23) % jitterWindow) - cfg.steppedFrameJitter;
      stepMs = (cfg.steppedFrameMs + jitter).clamp(38, 46);
    }
    if (_lastComicStepMs == 0 || nowMs - _lastComicStepMs >= stepMs) {
      _lastComicStepMs = nowMs;
      _comicVisualFrame += 1;
      if (widget.trailSkin.renderType != TrailRenderType.comic) {
        return;
      }
      final points = _buildAnimatedPathPointsUnit();
      if (points.length < 2) {
        _comicSnapshots = const <_ComicSnapshotState>[];
        return;
      }
      final offsetPattern = <Offset>[
        const Offset(-0.018, 0),
        const Offset(0.014, -0.012),
        const Offset(0.01, 0.016),
        const Offset(-0.012, 0.01),
        const Offset(0.016, -0.006),
      ];
      final next = <_ComicSnapshotState>[
        _ComicSnapshotState(
          points: points,
          frame: _comicVisualFrame,
          widthScale: const <double>[
            0.95,
            1.03,
            0.92,
            1.07,
            0.98
          ][_comicVisualFrame % 5],
          chromaOffset: offsetPattern[_comicVisualFrame % offsetPattern.length],
          createdAtMs: nowMs,
        ),
        ..._comicSnapshots,
      ];
      final maxCount = widget.trailSkin.snapshotCount.clamp(3, 8);
      _comicSnapshots = next.take(maxCount).toList(growable: false);
    }
  }

  GameBoardStatus get _currentStatus {
    return GameBoardStatus.fromPath(widget.level, _path);
  }

  void _applyInitialPath() {
    final sanitized = _sanitizePathPrefix(widget.initialPath);
    _path
      ..clear()
      ..addAll(sanitized);
    _syncGalaxyRevealProgressFromPath(forceRebuild: true);
    _clearTransientState();
    _resetAnimationState();
  }

  List<int> _sanitizePathPrefix(List<int> source) {
    if (source.isEmpty) return const <int>[];
    final valid = <int>[];
    final maxCell = widget.level.width * widget.level.height;
    for (final cell in source) {
      if (cell < 0 || cell >= maxCell) {
        break;
      }
      final canMove = GameBoardRules.canMoveToCell(
        widget.level,
        valid,
        _wallEdges,
        cell,
      );
      if (!canMove) {
        break;
      }
      valid.add(cell);
    }
    return valid;
  }

  int? _computeHintSourceCell() {
    if (_path.isNotEmpty) {
      return _path.last;
    }
    for (final entry in widget.level.numbers.entries) {
      if (entry.value == 1) return entry.key;
    }
    return null;
  }

  void _syncHintVisualState(GameBoard oldWidget) {
    final sourceCell = _computeHintSourceCell();
    final targetVisible = widget.hintVisible &&
        widget.hintDirection != HintDirection.none &&
        sourceCell != null;

    if (targetVisible) {
      _paintHintDirection = widget.hintDirection;
      _paintHintSourceCell = sourceCell;
      if (!oldWidget.hintVisible) {
        _hintController.duration = const Duration(milliseconds: 200);
        _hintController
          ..value = 0
          ..forward();
      } else if (_hintController.value == 0) {
        _hintController.forward();
      } else {
        _hintController.value = 1;
      }
      return;
    }

    if (oldWidget.hintVisible && _hintController.value > 0) {
      _hintController.duration = const Duration(milliseconds: 150);
      _hintController.reverse();
    }
  }

  void _handleHintAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() {
        _paintHintDirection = HintDirection.none;
        _paintHintSourceCell = null;
      });
    }
  }

  void _handleDrag(int? cell) {
    if (cell == null) {
      return;
    }

    if (_path.isNotEmpty && cell == _path.last) {
      return;
    }

    if (GameBoardRules.canBacktrackToPrevious(_path, cell)) {
      _handleBacktrackToPrevious();
      return;
    }

    if (!GameBoardRules.canMoveToCell(widget.level, _path, _wallEdges, cell)) {
      _handleRejectedMove(cell);
      return;
    }

    _handleForwardMove(cell);
  }

  void _handlePanCell(int? cell) {
    if (cell == null) {
      return;
    }
    if (_lastDragCell == cell) {
      return;
    }
    _lastDragCell = cell;
    _handleDrag(cell);
  }

  void _handleCellTap(int? cell) {
    if (cell == null) {
      return;
    }

    final visitedIndex = _path.indexOf(cell);
    if (visitedIndex >= 0) {
      if (visitedIndex == _path.length - 1) {
        return;
      }
      _handleRewindToCell(cell, visitedIndex);
      return;
    }

    if (!GameBoardRules.canMoveToCell(widget.level, _path, _wallEdges, cell)) {
      _handleRejectedMove(cell);
      return;
    }

    _handleForwardMove(cell);
  }

  void _handleForwardMove(int cell) {
    final previousUnit =
        _path.isNotEmpty ? _centerForCellUnit(_path.last) : null;
    final nextUnit = _centerForCellUnit(cell);
    setState(() {
      _path.add(cell);
      _clearTransientState();
      _startTransition(
        appearing: <int>[cell],
        disappearing: const <int>[],
      );
      if (_needsGalaxyRevealTrail) {
        if (previousUnit == null) {
          _galaxyRevealController.absorbPathUnit(
            <Offset>[nextUnit],
            enableSparkles: false,
            nowSec: DateTime.now().microsecondsSinceEpoch / 1000000.0,
          );
        } else {
          _galaxyRevealController.addSegmentUnit(
            previousUnit,
            nextUnit,
            enableSparkles: widget.trailSkin.galaxyReveal.enableSparkles,
            nowSec: DateTime.now().microsecondsSinceEpoch / 1000000.0,
          );
        }
      }
    });

    widget.onCellAdded?.call(cell, List<int>.unmodifiable(_path));
    _emitChange(GameBoardChangeType.add, <int>[cell]);
    _emitPathState();
  }

  void _handleBacktrackToPrevious() {
    final removedCell = _path.last;
    setState(() {
      _path.removeLast();
      _syncGalaxyRevealProgressFromPath(forceRebuild: true);
      _clearTransientState();
      _startTransition(
        appearing: const <int>[],
        disappearing: <int>[removedCell],
      );
    });

    _emitChange(GameBoardChangeType.backtrack, <int>[removedCell]);
    _emitPathState();
  }

  void _handleRewindToCell(int cell, int visitedIndex) {
    _resumeHighlightTimer?.cancel();
    final removedCells = _path.sublist(visitedIndex + 1);

    setState(() {
      _path.removeRange(visitedIndex + 1, _path.length);
      _syncGalaxyRevealProgressFromPath(forceRebuild: true);
      _clearTransientState();
      _highlightedResumeCell = cell;
      _startTransition(
        appearing: const <int>[],
        disappearing: removedCells,
      );
    });

    _resumeHighlightTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _highlightedResumeCell = null;
      });
    });

    _emitChange(GameBoardChangeType.rewind, removedCells);
    _emitPathState();
  }

  void _handleRejectedMove(int cell) {
    if (_path.isEmpty && !GameBoardRules.canStartAt(widget.level, cell)) {
      _showRejectedMove('Start on 1');
      return;
    }

    _showRejectedMove('Move blocked');
  }

  void _showRejectedMove(String message) {
    _errorTimer?.cancel();
    setState(() {
      _showErrorFlash = true;
    });

    widget.onInvalidMove?.call(message);

    _errorTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showErrorFlash = false;
      });
    });
  }

  void _clearTransientState() {
    _errorTimer?.cancel();
    _resumeHighlightTimer?.cancel();
    _showErrorFlash = false;
    _highlightedResumeCell = null;
  }

  void _resetPath() {
    if (_path.isEmpty) {
      return;
    }

    final removedCells = List<int>.from(_path);
    setState(() {
      _path.clear();
      if (_needsGalaxyRevealTrail) {
        _galaxyRevealController.reset();
      }
      _clearTransientState();
      _startTransition(
        appearing: const <int>[],
        disappearing: removedCells,
      );
    });
    _emitChange(GameBoardChangeType.reset, removedCells);
    _emitPathState();
  }

  void _undoLastStep() {
    if (_path.isEmpty) {
      return;
    }

    final removedCell = _path.last;
    setState(() {
      _path.removeLast();
      _syncGalaxyRevealProgressFromPath(forceRebuild: true);
      _clearTransientState();
      _startTransition(
        appearing: const <int>[],
        disappearing: <int>[removedCell],
      );
    });
    _emitChange(GameBoardChangeType.undo, <int>[removedCell]);
    _emitPathState();
  }

  void _startTransition({
    required List<int> appearing,
    required List<int> disappearing,
  }) {
    _appearingCells = appearing;
    _disappearingCells = disappearing;
    _transitionController
      ..value = 0
      ..forward().whenCompleteOrCancel(() {
        if (!mounted) {
          return;
        }
        setState(() {
          _resetAnimationState();
        });
      });
  }

  void _resetAnimationState() {
    _appearingCells = const <int>[];
    _disappearingCells = const <int>[];
    _transitionController.value = 1;
  }

  void _emitChange(GameBoardChangeType type, List<int> affectedCells) {
    widget.onChange?.call(
      GameBoardChange(
        type: type,
        path: List<int>.unmodifiable(_path),
        affectedCells: List<int>.unmodifiable(affectedCells),
      ),
    );
  }

  void _emitPathState() {
    final pathSnapshot = List<int>.unmodifiable(_path);
    widget.onPathChanged?.call(pathSnapshot);
    widget.onStatusChanged?.call(_currentStatus);
  }

  Future<void> _syncPointerSkin() async {
    final targetPath = widget.pointerAssetPath;
    if (targetPath == null || targetPath.isEmpty) {
      if (!mounted) return;
      setState(() {
        _pointerImage = null;
        _loadedPointerAssetPath = null;
      });
      return;
    }
    if (_loadedPointerAssetPath == targetPath && _pointerImage != null) {
      return;
    }
    if (kIsWeb &&
        (targetPath.startsWith('http://') ||
            targetPath.startsWith('https://'))) {
      if (!mounted) return;
      setState(() {
        _pointerImage = null;
        _loadedPointerAssetPath = targetPath;
      });
      return;
    }

    try {
      late final ui.Image image;
      if (targetPath.startsWith('assets/')) {
        final bytes = await rootBundle.load(targetPath);
        image = await decodeImageFromList(bytes.buffer.asUint8List());
      } else if (targetPath.startsWith('http://') ||
          targetPath.startsWith('https://')) {
        final uri = Uri.parse(targetPath);
        Uint8List bytes;
        if (kIsWeb) {
          final data = await NetworkAssetBundle(uri).load(targetPath);
          bytes = data.buffer.asUint8List();
        } else {
          final client = HttpClient();
          try {
            final req = await client.getUrl(uri);
            final resp = await req.close();
            if (resp.statusCode < 200 || resp.statusCode >= 300) {
              throw HttpException(
                'HTTP ${resp.statusCode} loading $targetPath',
                uri: uri,
              );
            }
            bytes = await consolidateHttpClientResponseBytes(resp);
          } finally {
            client.close();
          }
        }
        image = await decodeImageFromList(bytes);
      } else if (targetPath.startsWith('data:image')) {
        final comma = targetPath.indexOf(',');
        if (comma <= 0 || comma >= targetPath.length - 1) {
          throw StateError('Invalid data URI for pointer skin');
        }
        final bytes = base64Decode(targetPath.substring(comma + 1));
        image = await decodeImageFromList(bytes);
      } else {
        if (kIsWeb) {
          throw StateError('File pointer skins are not supported on web');
        }
        final fileBytes = await File(targetPath).readAsBytes();
        image = await decodeImageFromList(fileBytes);
      }
      if (!mounted || widget.pointerAssetPath != targetPath) {
        return;
      }
      setState(() {
        _pointerImage = image;
        _loadedPointerAssetPath = targetPath;
      });
    } catch (_) {
      if (!mounted || widget.pointerAssetPath != targetPath) {
        return;
      }
      if (kDebugMode) {
        debugPrint('[PointerSkin] Failed to load: $targetPath');
      }
      setState(() {
        _pointerImage = null;
        _loadedPointerAssetPath = null;
      });
    }
  }

  Widget? _buildPointerOverlayWidget(double cellSize) {
    if (!kIsWeb) return null;
    final path = widget.pointerAssetPath;
    if (path == null || path.isEmpty) return null;
    final isRemote = path.startsWith('http://') || path.startsWith('https://');
    if (!isRemote) return null;
    if (_path.isEmpty) return null;
    final cell = _path.last;
    final row = cell ~/ widget.level.width;
    final col = cell % widget.level.width;
    final inset = cellSize * 0.08;
    if (_webPointerStartedPaths.add(path) && kDebugMode) {
      debugPrint('[PointerSkin] Web pointer start: $path');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_webPointerLoadedPaths.add(path) && kDebugMode) {
        debugPrint('[PointerSkin] Web pointer loaded: $path');
      }
    });
    return Positioned(
      left: col * cellSize + inset,
      top: row * cellSize + inset,
      width: cellSize - inset * 2,
      height: cellSize - inset * 2,
      child: IgnorePointer(
        child: ClipRect(
          child: buildNetworkImageCompat(
            url: path,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            fallback: Builder(
              builder: (_) {
                if (_webPointerFailedPaths.add(path) && kDebugMode) {
                  debugPrint('[PointerSkin] Web pointer failed: $path');
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildHintOverlayWidget({
    required double maxWidth,
    required double cellSize,
    required int? hintCell,
  }) {
    if (_paintHintDirection == HintDirection.none ||
        hintCell == null ||
        _hintController.value <= 0) {
      return null;
    }
    final pathColor =
        widget.pathColorOverride ?? widget.gameTheme.pathColorDarkVariant;
    return IgnorePointer(
      child: CustomPaint(
        painter: _HintOverlayPainter(
          level: widget.level,
          hintDirection: _paintHintDirection,
          hintSourceCell: hintCell,
          hintOpacity: _hintController.value,
          hintColor: pathColor,
        ),
        size: Size(maxWidth, cellSize * widget.level.height),
      ),
    );
  }

  int? _cellIndexForOffset(Offset localPosition, double boardWidth) {
    final cellSize = boardWidth / widget.level.width;
    final boardHeight = cellSize * widget.level.height;

    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx >= boardWidth ||
        localPosition.dy >= boardHeight) {
      return null;
    }

    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();
    return row * widget.level.width + col;
  }

  List<TrailSnapshot> _buildComicPainterSnapshots(double cellSize) {
    if (_comicSnapshots.isEmpty) return const <TrailSnapshot>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = <TrailSnapshot>[];
    for (var i = 0; i < _comicSnapshots.length; i++) {
      final snap = _comicSnapshots[i];
      final ageMs = now - snap.createdAtMs;
      final ageFade = (1 - (ageMs / 1000.0)).clamp(0.0, 1.0);
      final stackFade = (1 - (i * 0.18)).clamp(0.0, 1.0);
      final opacity = (ageFade * stackFade).clamp(0.0, 1.0);
      if (opacity <= 0.02) continue;
      final scaled = snap.points
          .map((p) => Offset(p.dx * cellSize, p.dy * cellSize))
          .toList(growable: false);
      result.add(
        TrailSnapshot(
          points: scaled,
          opacity: opacity,
          widthScale: snap.widthScale,
          frame: snap.frame,
          chromaOffset: Offset(
            snap.chromaOffset.dx * cellSize,
            snap.chromaOffset.dy * cellSize,
          ),
        ),
      );
    }
    return result;
  }

  List<Offset> _buildAnimatedPathPointsUnit() {
    final points = _path.map((cell) => _centerForCellUnit(cell)).toList();
    if (points.length < 2) {
      return points;
    }
    final easedT = Curves.easeOutCubic.transform(transitionValue.clamp(0, 1));
    if (_appearingCells.length == 1 && _path.last == _appearingCells.first) {
      final from = points[points.length - 2];
      final to = points.last;
      points[points.length - 1] = Offset.lerp(from, to, easedT)!;
      return points;
    }
    if (_disappearingCells.isNotEmpty) {
      final anchor = points.last;
      final removed = _centerForCellUnit(_disappearingCells.first);
      points.add(Offset.lerp(removed, anchor, easedT)!);
    }
    return points;
  }

  double get transitionValue => _transitionController.value;

  Offset _centerForCellUnit(int cell) {
    final row = cell ~/ widget.level.width;
    final col = cell % widget.level.width;
    return Offset(col + 0.5, row + 0.5);
  }
}

class _ComicSnapshotState {
  const _ComicSnapshotState({
    required this.points,
    required this.frame,
    required this.widthScale,
    required this.chromaOffset,
    required this.createdAtMs,
  });

  final List<Offset> points;
  final int frame;
  final double widthScale;
  final Offset chromaOffset;
  final int createdAtMs;
}

class _GameBoardPainter extends CustomPainter {
  _GameBoardPainter({
    required this.level,
    required this.gameTheme,
    required this.pathColorOverride,
    required this.trailSkin,
    required this.trailPhase,
    required this.visualPhase,
    required this.visualFrame,
    required this.comicSnapshots,
    required this.pointerImage,
    required this.smokePuffImages,
    required this.punkIconImages,
    required this.webTrailSprites,
    required this.webLegendaryTrailSprites,
    required this.comicSpiderverseTrailSprites,
    required this.comicSpiderverseRebuiltTrailSprites,
    required this.urbanGraffitiTrailSprites,
    required this.galaxyRevealTexture,
    required this.galaxyRevealController,
    required this.comicSpiderverseBoardBackground,
    required this.path,
    required this.opponentPath,
    required this.opponentTrailColor,
    required this.solved,
    required this.hintDirection,
    required this.hintSourceCell,
    required this.hintOpacity,
    required this.highlightedResumeCell,
    required this.showErrorFlash,
    required this.appearingCells,
    required this.disappearingCells,
    required this.transitionValue,
  });

  final Level level;
  final GameTheme gameTheme;
  final Color? pathColorOverride;
  final TrailSkinConfig trailSkin;
  final double trailPhase;
  final double visualPhase;
  final int visualFrame;
  final List<TrailSnapshot> comicSnapshots;
  final ui.Image? pointerImage;
  final List<ui.Image> smokePuffImages;
  final List<ui.Image> punkIconImages;
  final WebTrailSprites webTrailSprites;
  final WebLegendaryTrailSprites webLegendaryTrailSprites;
  final ComicSpiderverseTrailSprites comicSpiderverseTrailSprites;
  final ComicSpiderverseRebuiltSprites comicSpiderverseRebuiltTrailSprites;
  final UrbanGraffitiTrailSprites urbanGraffitiTrailSprites;
  final ui.Image? galaxyRevealTexture;
  final GalaxyRevealTrailController galaxyRevealController;
  final ui.Image? comicSpiderverseBoardBackground;
  final List<int> path;
  final List<int> opponentPath;
  final Color? opponentTrailColor;
  final bool solved;
  final HintDirection hintDirection;
  final int? hintSourceCell;
  final double hintOpacity;
  final int? highlightedResumeCell;
  final bool showErrorFlash;
  final List<int> appearingCells;
  final List<int> disappearingCells;
  final double transitionValue;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / level.width;
    final pathColor = pathColorOverride ?? gameTheme.pathColor;
    final pathDarkColor = _adjustPathDepth(pathColor);
    final boardRect = Offset.zero & size;
    final radius = Radius.circular(max(20, cellSize * 0.45));
    final boardRRect = RRect.fromRectAndRadius(boardRect, radius);
    canvas.save();
    canvas.clipRRect(boardRRect);
    canvas.drawRRect(
      boardRRect,
      Paint()
        ..color = gameTheme.boardColor
        ..style = PaintingStyle.fill,
    );
    _drawComicSpiderverseBoardBackground(canvas, boardRect);
    final isGalaxyRevealActive =
        trailSkin.renderType == TrailRenderType.galaxyReveal &&
            !kGalaxyRevealRollbackToBoardColor;
    if (isGalaxyRevealActive &&
        galaxyRevealTexture != null) {
      final playableRect = boardRect.deflate(max(2.0, cellSize * 0.1));
      GalaxyRevealTrailPainter(
        boardRect: boardRect,
        playableRect: playableRect,
        cellSize: cellSize,
        textureImage: galaxyRevealTexture!,
        controller: galaxyRevealController,
        config: trailSkin.galaxyReveal,
        nowSec: DateTime.now().microsecondsSinceEpoch / 1000000.0,
      ).paint(canvas, size);
    }

    final baseFillColor = trailSkin.renderType == TrailRenderType.galaxyReveal &&
            kGalaxyRevealRollbackToBoardColor
        ? gameTheme.boardColor
        : (solved ? pathDarkColor : pathColor);
    final visitedFillPaint = Paint()..style = PaintingStyle.fill;
    final useVisitedCellFill = trailSkin.renderType != TrailRenderType.galaxyReveal ||
        kGalaxyRevealRollbackToBoardColor;
    final resumePaint = Paint()
      ..color = pathColor.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2, cellSize * 0.08);

    if (useVisitedCellFill) {
      for (final cell in path) {
        final alpha = appearingCells.contains(cell) ? transitionValue : 1.0;
        _drawCellFill(
          canvas,
          cellSize,
          cell,
          visitedFillPaint..color = baseFillColor.withOpacity(0.25 * alpha),
        );
      }

      if (path.isNotEmpty) {
        _drawCellFill(
          canvas,
          cellSize,
          path.last,
          visitedFillPaint
            ..color =
                Color.lerp(pathColor, Colors.white, 0.35)!.withOpacity(0.36),
        );
      }

      for (final cell in disappearingCells) {
        final alpha = 1 - transitionValue;
        if (alpha <= 0) {
          continue;
        }
        _drawCellFill(
          canvas,
          cellSize,
          cell,
          visitedFillPaint..color = baseFillColor.withOpacity(0.25 * alpha),
        );
      }
    }

    if (highlightedResumeCell != null) {
      final row = highlightedResumeCell! ~/ level.width;
      final col = highlightedResumeCell! % level.width;
      final rect = Rect.fromLTWH(
        col * cellSize + 2,
        row * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      canvas.drawRect(rect, resumePaint);
    }

    if (path.length > 1) {
      final markerRadius = cellSize * 0.24;
      final markerClipPath =
          _buildMarkerClipPath(size, cellSize, markerRadius + 2);
      final liquidPoints = _buildAnimatedPathPoints(cellSize);
      final liquidPath = _buildSmoothPath(liquidPoints);
      final trailSkin = _resolvedTrailSkin(pathColor, pathDarkColor);
      final nodeCenters = level.numbers.keys
          .map((idx) => _centerForCell(idx, cellSize))
          .toList(growable: false);
      final ctx = TrailRenderContext(
        canvas: canvas,
        boardRect: boardRect,
        pathCurve: liquidPath,
        pathPoints: liquidPoints,
        headPosition: liquidPoints.isNotEmpty ? liquidPoints.last : null,
        cellSize: cellSize,
        baseStrokeWidth: cellSize * PATH_WIDTH_RATIO,
        trailSkin: trailSkin,
        phase: trailPhase,
        visualPhase: visualPhase,
        visualFrame: visualFrame,
        solved: solved,
        clipPath: markerClipPath,
        nowSeconds: DateTime.now().microsecondsSinceEpoch / 1000000.0,
        nodeCenters: nodeCenters,
        snapshots: comicSnapshots,
        smokeSprites: smokePuffImages,
        iconSprites: punkIconImages,
        webSprites: webTrailSprites,
        webLegendarySprites: webLegendaryTrailSprites,
        comicSpiderverseSprites: comicSpiderverseTrailSprites,
        comicSpiderverseRebuiltSprites: comicSpiderverseRebuiltTrailSprites,
        urbanGraffitiSprites: urbanGraffitiTrailSprites,
      );

      canvas.save();
      canvas.clipPath(markerClipPath);
      TrailRenderer.paintBase(ctx);
      TrailRenderer.paintVfx(ctx);
      canvas.restore();
    }

    if (opponentPath.length > 1) {
      final opponentPoints = opponentPath
          .map((cell) => _centerForCell(cell, cellSize))
          .toList(growable: false);
      final opponentCurve = _buildSmoothPath(opponentPoints);
      final baseColor = opponentTrailColor ?? const Color(0xFFE2538A);
      final opponentGlow = Paint()
        ..color = baseColor.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = cellSize * 0.72
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final opponentStroke = Paint()
        ..color = baseColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = cellSize * 0.48;
      canvas.drawPath(opponentCurve, opponentGlow);
      canvas.drawPath(opponentCurve, opponentStroke);
    }

    if (hintDirection != HintDirection.none &&
        hintSourceCell != null &&
        hintOpacity > 0) {
      _drawHintArrow(
        canvas,
        cellSize,
        hintSourceCell!,
        hintDirection,
        hintOpacity,
        pathDarkColor,
      );
    }

    final gridPaint = Paint()
      ..color = gameTheme.gridColor
      ..strokeWidth = 1;

    for (var x = 0; x <= level.width; x++) {
      final dx = x * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    for (var y = 0; y <= level.height; y++) {
      final dy = y * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final wallPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = max(4, cellSize * 0.12)
      ..strokeCap = StrokeCap.square;

    for (final wall in level.walls) {
      final a = wall.cell1;
      final b = wall.cell2;
      final aRow = a ~/ level.width;
      final aCol = a % level.width;
      final bRow = b ~/ level.width;
      final bCol = b % level.width;

      if (aRow == bRow && (aCol - bCol).abs() == 1) {
        final boundaryCol = max(aCol, bCol);
        final x = boundaryCol * cellSize;
        final y1 = aRow * cellSize;
        final y2 = (aRow + 1) * cellSize;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), wallPaint);
      } else if (aCol == bCol && (aRow - bRow).abs() == 1) {
        final boundaryRow = max(aRow, bRow);
        final y = boundaryRow * cellSize;
        final x1 = aCol * cellSize;
        final x2 = (aCol + 1) * cellSize;
        canvas.drawLine(Offset(x1, y), Offset(x2, y), wallPaint);
      }
    }

    for (final entry in level.numbers.entries) {
      final index = entry.key;
      final value = entry.value;
      final row = index ~/ level.width;
      final col = index % level.width;
      final center = Offset(
        (col * cellSize) + cellSize / 2,
        (row * cellSize) + cellSize / 2,
      );
      canvas.drawCircle(
        center,
        cellSize * 0.24,
        Paint()
          ..color = gameTheme.boardColor.computeLuminance() < 0.3
              ? const Color(0xFF1D1D21)
              : Colors.black,
      );

      final display = level.displayLabels[value] ?? value.toString();
      final charCount = display.runes.length;
      final baseScale = charCount >= 4
          ? 0.16
          : charCount == 3
              ? 0.19
              : charCount == 2
                  ? 0.23
                  : 0.27;
      final textPainter = TextPainter(
        text: TextSpan(
          text: display,
          style: TextStyle(
            color: Colors.white,
            fontSize: cellSize * baseScale,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final dx = (col * cellSize) + (cellSize - textPainter.width) / 2;
      final dy = (row * cellSize) + (cellSize - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    }

    if (path.isNotEmpty) {
      _drawPointerImage(canvas, cellSize, path.last);
    }

    if (showErrorFlash) {
      canvas.drawRRect(
        boardRRect,
        Paint()
          ..color = Colors.red.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, cellSize * 0.08),
      );
    }
    canvas.restore();
  }

  void _drawCellFill(Canvas canvas, double cellSize, int cell, Paint paint) {
    final row = cell ~/ level.width;
    final col = cell % level.width;
    final rect = Rect.fromLTWH(
      col * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );
    canvas.drawRect(rect, paint);
  }

  void _drawComicSpiderverseBoardBackground(Canvas canvas, Rect boardRect) {
    final image = comicSpiderverseBoardBackground;
    if (image == null) return;

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final imageAspect = imageWidth / imageHeight;
    final boardAspect = boardRect.width / boardRect.height;

    Rect src;
    if (imageAspect > boardAspect) {
      final srcWidth = imageHeight * boardAspect;
      final left = (imageWidth - srcWidth) * 0.5;
      src = Rect.fromLTWH(left, 0, srcWidth, imageHeight);
    } else {
      final srcHeight = imageWidth / boardAspect;
      final top = (imageHeight - srcHeight) * 0.5;
      src = Rect.fromLTWH(0, top, imageWidth, srcHeight);
    }

    canvas.drawImageRect(
      image,
      src,
      boardRect,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..color = Colors.white.withOpacity(0.3),
    );
  }

  void _drawPointerImage(Canvas canvas, double cellSize, int cell) {
    final image = pointerImage;
    if (image == null) {
      return;
    }
    final row = cell ~/ level.width;
    final col = cell % level.width;
    final inset = cellSize * 0.08;
    final dst = Rect.fromLTWH(
      col * cellSize + inset,
      row * cellSize + inset,
      cellSize - inset * 2,
      cellSize - inset * 2,
    );
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, Paint()..isAntiAlias = true);
  }

  List<Offset> _buildAnimatedPathPoints(double cellSize) {
    final points = path.map((cell) => _centerForCell(cell, cellSize)).toList();
    if (points.length < 2) {
      return points;
    }
    final easedT = Curves.easeOutCubic.transform(transitionValue.clamp(0, 1));

    if (appearingCells.length == 1 && path.last == appearingCells.first) {
      final from = points[points.length - 2];
      final to = points.last;
      points[points.length - 1] = Offset.lerp(from, to, easedT)!;
      return points;
    }

    if (disappearingCells.isNotEmpty) {
      final anchor = points.last;
      final removed = _centerForCell(disappearingCells.first, cellSize);
      points.add(Offset.lerp(removed, anchor, easedT)!);
    }

    return points;
  }

  Offset _centerForCell(int cell, double cellSize) {
    final row = cell ~/ level.width;
    final col = cell % level.width;
    return Offset(
        (col * cellSize) + cellSize / 2, (row * cellSize) + cellSize / 2);
  }

  Path _buildSmoothPath(List<Offset> points) {
    final pathShape = Path();
    if (points.isEmpty) {
      return pathShape;
    }
    if (points.length == 1) {
      pathShape.moveTo(points.first.dx, points.first.dy);
      return pathShape;
    }
    if (points.length == 2) {
      pathShape
        ..moveTo(points.first.dx, points.first.dy)
        ..lineTo(points.last.dx, points.last.dy);
      return pathShape;
    }

    pathShape.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      final midpointA =
          Offset((prev.dx + current.dx) / 2, (prev.dy + current.dy) / 2);
      final midpointB =
          Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      if (i == 1) {
        pathShape.lineTo(midpointA.dx, midpointA.dy);
      }
      pathShape.quadraticBezierTo(
        current.dx,
        current.dy,
        midpointB.dx,
        midpointB.dy,
      );
    }
    pathShape.lineTo(points.last.dx, points.last.dy);
    return pathShape;
  }

  Path _buildMarkerClipPath(
      Size size, double cellSize, double protectedRadius) {
    final boardPath = Path()..addRect(Offset.zero & size);
    final markerHoles = Path();
    for (final entry in level.numbers.entries) {
      markerHoles.addOval(
        Rect.fromCircle(
          center: _centerForCell(entry.key, cellSize),
          radius: protectedRadius,
        ),
      );
    }
    return Path.combine(PathOperation.difference, boardPath, markerHoles);
  }

  void _drawHintArrow(
    Canvas canvas,
    double cellSize,
    int sourceCell,
    HintDirection direction,
    double opacity,
    Color arrowColor,
  ) {
    final row = sourceCell ~/ level.width;
    final col = sourceCell % level.width;
    final center = Offset(
      (col * cellSize) + cellSize / 2,
      (row * cellSize) + cellSize / 2,
    );
    final length = cellSize * 0.32;

    Offset vector;
    switch (direction) {
      case HintDirection.up:
        vector = Offset(0, -length);
        break;
      case HintDirection.down:
        vector = Offset(0, length);
        break;
      case HintDirection.left:
        vector = Offset(-length, 0);
        break;
      case HintDirection.right:
        vector = Offset(length, 0);
        break;
      case HintDirection.none:
        return;
    }

    final end = center + vector;
    final arrowPaint = Paint()
      ..color = arrowColor.withOpacity(opacity)
      ..strokeWidth = max(2, cellSize * 0.07)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, end, arrowPaint);

    final headSize = cellSize * 0.14;
    final ux = vector.dx / length;
    final uy = vector.dy / length;
    final left = Offset(
      end.dx - ux * headSize - uy * headSize * 0.7,
      end.dy - uy * headSize + ux * headSize * 0.7,
    );
    final right = Offset(
      end.dx - ux * headSize + uy * headSize * 0.7,
      end.dy - uy * headSize - ux * headSize * 0.7,
    );
    canvas.drawLine(end, left, arrowPaint);
    canvas.drawLine(end, right, arrowPaint);
  }

  Color _adjustPathDepth(Color color) {
    final hsl = HSLColor.fromColor(color);
    final delta = gameTheme.boardColor.computeLuminance() < 0.3 ? 0.14 : -0.16;
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness.toDouble()).toColor();
  }

  TrailSkinConfig _resolvedTrailSkin(Color pathColor, Color pathDarkColor) {
    if (trailSkin.renderType != TrailRenderType.basic) {
      return trailSkin;
    }
    return TrailSkinConfig(
      id: trailSkin.id,
      name: trailSkin.name,
      renderType: trailSkin.renderType,
      primaryColor: pathColor,
      secondaryColor: pathDarkColor,
      thickness: trailSkin.thickness,
      opacity: trailSkin.opacity,
      glow: trailSkin.glow,
      headAssetPath: trailSkin.headAssetPath,
      effectIntensity: trailSkin.effectIntensity,
      particle: trailSkin.particle,
      visualStepFps: trailSkin.visualStepFps,
      snapshotCount: trailSkin.snapshotCount,
      chromaOffsetPx: trailSkin.chromaOffsetPx,
      web: trailSkin.web,
      webLegendary: trailSkin.webLegendary,
      comicSpiderverse: trailSkin.comicSpiderverse,
      comicSpiderverseV2: trailSkin.comicSpiderverseV2,
      comicSpiderverseRebuilt: trailSkin.comicSpiderverseRebuilt,
      urbanGraffiti: trailSkin.urbanGraffiti,
      ink: trailSkin.ink,
      arc: trailSkin.arc,
      golden: trailSkin.golden,
      aura: trailSkin.aura,
      smoke: trailSkin.smoke,
    );
  }

  @override
  bool shouldRepaint(covariant _GameBoardPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.gameTheme != gameTheme ||
        oldDelegate.pathColorOverride != pathColorOverride ||
        oldDelegate.trailSkin != trailSkin ||
        oldDelegate.trailPhase != trailPhase ||
        oldDelegate.visualPhase != visualPhase ||
        oldDelegate.visualFrame != visualFrame ||
        oldDelegate.comicSnapshots != comicSnapshots ||
        oldDelegate.pointerImage != pointerImage ||
        oldDelegate.smokePuffImages != smokePuffImages ||
        oldDelegate.punkIconImages != punkIconImages ||
        oldDelegate.webTrailSprites != webTrailSprites ||
        oldDelegate.webLegendaryTrailSprites != webLegendaryTrailSprites ||
        oldDelegate.comicSpiderverseTrailSprites !=
            comicSpiderverseTrailSprites ||
        oldDelegate.comicSpiderverseRebuiltTrailSprites !=
            comicSpiderverseRebuiltTrailSprites ||
        oldDelegate.urbanGraffitiTrailSprites != urbanGraffitiTrailSprites ||
        oldDelegate.galaxyRevealTexture != galaxyRevealTexture ||
        oldDelegate.galaxyRevealController != galaxyRevealController ||
        oldDelegate.comicSpiderverseBoardBackground !=
            comicSpiderverseBoardBackground ||
        oldDelegate.path != path ||
        oldDelegate.opponentPath != opponentPath ||
        oldDelegate.opponentTrailColor != opponentTrailColor ||
        oldDelegate.solved != solved ||
        oldDelegate.hintDirection != hintDirection ||
        oldDelegate.hintSourceCell != hintSourceCell ||
        oldDelegate.hintOpacity != hintOpacity ||
        oldDelegate.highlightedResumeCell != highlightedResumeCell ||
        oldDelegate.showErrorFlash != showErrorFlash ||
        oldDelegate.appearingCells != appearingCells ||
        oldDelegate.disappearingCells != disappearingCells ||
        oldDelegate.transitionValue != transitionValue;
  }
}

class _HintOverlayPainter extends CustomPainter {
  const _HintOverlayPainter({
    required this.level,
    required this.hintDirection,
    required this.hintSourceCell,
    required this.hintOpacity,
    required this.hintColor,
  });

  final Level level;
  final HintDirection hintDirection;
  final int? hintSourceCell;
  final double hintOpacity;
  final Color hintColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (hintDirection == HintDirection.none ||
        hintSourceCell == null ||
        hintOpacity <= 0) {
      return;
    }
    final cellSize = size.width / level.width;
    final row = hintSourceCell! ~/ level.width;
    final col = hintSourceCell! % level.width;
    final center = Offset(
      (col * cellSize) + cellSize / 2,
      (row * cellSize) + cellSize / 2,
    );
    final length = cellSize * 0.32;

    Offset vector;
    switch (hintDirection) {
      case HintDirection.up:
        vector = Offset(0, -length);
        break;
      case HintDirection.down:
        vector = Offset(0, length);
        break;
      case HintDirection.left:
        vector = Offset(-length, 0);
        break;
      case HintDirection.right:
        vector = Offset(length, 0);
        break;
      case HintDirection.none:
        return;
    }

    final end = center + vector;
    final arrowPaint = Paint()
      ..color = hintColor.withOpacity(hintOpacity)
      ..strokeWidth = max(2, cellSize * 0.07)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, end, arrowPaint);

    final headSize = cellSize * 0.14;
    final ux = vector.dx / length;
    final uy = vector.dy / length;
    final left = Offset(
      end.dx - ux * headSize - uy * headSize * 0.7,
      end.dy - uy * headSize + ux * headSize * 0.7,
    );
    final right = Offset(
      end.dx - ux * headSize + uy * headSize * 0.7,
      end.dy - uy * headSize - ux * headSize * 0.7,
    );
    canvas.drawLine(end, left, arrowPaint);
    canvas.drawLine(end, right, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _HintOverlayPainter oldDelegate) {
    return oldDelegate.hintDirection != hintDirection ||
        oldDelegate.hintSourceCell != hintSourceCell ||
        oldDelegate.hintOpacity != hintOpacity ||
        oldDelegate.hintColor != hintColor ||
        oldDelegate.level != level;
  }
}
