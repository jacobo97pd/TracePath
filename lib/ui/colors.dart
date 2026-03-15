import 'package:flutter/material.dart';

class UiColors {
  const UiColors._();

  static const Color white = Color(0xFFFFFFFF);
  static const Color blackPrimary = Color(0xFF111111);
  static const Color greySecondary = Color(0xFF666666);
  static const Color lineLight = Color(0xFFEAEAEA);

  static const Color darkBackground = Color(0xFF0F0F10);
  static const Color darkSurface = Color(0xFF1A1A1D);
  static const Color darkPrimary = Color(0xFFECECEC);
  static const Color darkSecondary = Color(0xFFB5B5B9);
  static const Color lineDark = Color(0xFF2A2A2E);

  static Color background(Brightness brightness) {
    return brightness == Brightness.dark ? darkBackground : white;
  }

  static Color surface(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurface : white;
  }

  static Color primary(Brightness brightness) {
    return brightness == Brightness.dark ? darkPrimary : blackPrimary;
  }

  static Color secondary(Brightness brightness) {
    return brightness == Brightness.dark ? darkSecondary : greySecondary;
  }

  static Color divider(Brightness brightness) {
    return brightness == Brightness.dark ? lineDark : lineLight;
  }
}
