class Wall {
  const Wall({required this.cell1, required this.cell2});

  final int cell1;
  final int cell2;

  factory Wall.fromJson(Map<String, dynamic> json) {
    return Wall(
      cell1: json['cell1'] as int,
      cell2: json['cell2'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cell1': cell1,
      'cell2': cell2,
    };
  }
}

class Level {
  const Level({
    required this.id,
    required this.width,
    required this.height,
    required this.numbers,
    required this.walls,
    required this.solution,
    required this.difficulty,
    required this.pack,
    this.displayLabels = const <int, String>{},
  });

  final String id;
  final int width;
  final int height;
  final Map<int, int> numbers;
  final List<Wall> walls;
  final List<int> solution;
  final int difficulty;
  final String pack;
  final Map<int, String> displayLabels;

  factory Level.fromJson(Map<String, dynamic> json) {
    final rawNumbers = json['numbers'] as Map<String, dynamic>;
    final rawDisplayLabels =
        (json['displayLabels'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return Level(
      id: json['id'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      numbers: rawNumbers.map((k, v) => MapEntry(int.parse(k), v as int)),
      walls: (json['walls'] as List<dynamic>)
          .map((w) => Wall.fromJson(w as Map<String, dynamic>))
          .toList(),
      solution: (json['solution'] as List<dynamic>).cast<int>(),
      difficulty: json['difficulty'] as int,
      pack: json['pack'] as String,
      displayLabels: rawDisplayLabels.map(
        (k, v) => MapEntry(int.parse(k), v.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'width': width,
      'height': height,
      'numbers': numbers.map((k, v) => MapEntry(k.toString(), v)),
      'walls': walls.map((w) => w.toJson()).toList(),
      'solution': solution,
      'difficulty': difficulty,
      'pack': pack,
      'displayLabels': displayLabels.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}

class GridSize {
  const GridSize({required this.width, required this.height});

  final int width;
  final int height;
}

class PackDef {
  const PackDef({
    required this.id,
    required this.levelCount,
    required this.gridSizes,
    required this.wallDensity,
    this.unlockRequirements = const PackUnlockRequirements(),
  });

  final String id;
  final int levelCount;
  final List<GridSize> gridSizes;
  final double wallDensity;
  final PackUnlockRequirements unlockRequirements;
}

class PackUnlockRequirements {
  const PackUnlockRequirements({
    this.requiredClassicLevels = 0,
    this.requiredTotalCampaignLevels = 0,
    this.requiredAtOrAboveDifficulty = 0,
    this.difficultyThreshold = 4,
  });

  final int requiredClassicLevels;
  final int requiredTotalCampaignLevels;
  final int requiredAtOrAboveDifficulty;
  final int difficultyThreshold;

  bool get isAlwaysUnlocked {
    return requiredClassicLevels <= 0 &&
        requiredTotalCampaignLevels <= 0 &&
        requiredAtOrAboveDifficulty <= 0;
  }
}
