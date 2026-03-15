import 'dart:math';

import 'package:flutter/material.dart';

class GameTheme {
  const GameTheme({
    required this.pathColor,
    required this.pathColorDarkVariant,
    required this.backgroundColor,
    required this.boardColor,
    required this.gridColor,
  });

  final Color pathColor;
  final Color pathColorDarkVariant;
  final Color backgroundColor;
  final Color boardColor;
  final Color gridColor;
}

class ThemeGenerator {
  ThemeGenerator._();

  static const List<Color> _pathPalette = <Color>[
    Color(0xFFF08B44),
    Color(0xFF2FACA4),
    Color(0xFF7666D9),
    Color(0xFFF26F5A),
    Color(0xFF4A88DC),
    Color(0xFF4AA96C),
  ];

  static GameTheme generateTheme({
    required int seed,
    required Brightness brightness,
  }) {
    final pathColor = generatePathColor(seed);
    final darkPath = adjustForDarkMode(pathColor);
    final isDark = brightness == Brightness.dark;

    return GameTheme(
      pathColor: isDark ? darkPath : pathColor,
      pathColorDarkVariant: isDark
          ? _adjustLightness(darkPath, 0.15)
          : _adjustLightness(pathColor, -0.18),
      backgroundColor:
          isDark ? const Color(0xFF0F0F10) : const Color(0xFFFAFAF9),
      boardColor:
          isDark ? const Color(0xFF2A3346) : const Color(0xFFFFFFFF),
      gridColor:
          isDark ? const Color(0xFF4E5E7A) : const Color(0xFFE6E6E3),
    );
  }

  static Color generatePathColor(int seed) {
    final index = seed.abs() % _pathPalette.length;
    return _pathPalette[index];
  }

  static Color adjustForDarkMode(Color color) {
    final hsl = HSLColor.fromColor(color);
    final nextLightness = (hsl.lightness + 0.18).clamp(0.52, 0.74);
    final nextSaturation = (hsl.saturation + 0.08).clamp(0.45, 0.95);
    return hsl
        .withLightness(nextLightness.toDouble())
        .withSaturation(nextSaturation.toDouble())
        .toColor();
  }

  static Color _adjustLightness(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + delta).clamp(0.0, 1.0);
    return hsl.withLightness(lightness.toDouble()).toColor();
  }

  static int seedFromLevelId(String levelId) {
    var hash = 0;
    for (var i = 0; i < levelId.length; i++) {
      hash = 0x1fffffff & (hash + levelId.codeUnitAt(i));
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return max(hash, 1);
  }
}
