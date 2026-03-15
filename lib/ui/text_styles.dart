import 'package:flutter/material.dart';

import 'colors.dart';

class UiTextStyles {
  const UiTextStyles._();

  static TextStyle pageTitle(Brightness brightness) {
    return TextStyle(
      fontSize: 42,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: UiColors.primary(brightness),
    );
  }

  static TextStyle subtitle(Brightness brightness) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: UiColors.secondary(brightness),
    );
  }

  static TextStyle sectionTitle(Brightness brightness) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: UiColors.primary(brightness),
    );
  }

  static TextStyle body(Brightness brightness) {
    return TextStyle(
      fontSize: 14,
      color: UiColors.secondary(brightness),
    );
  }

  static TextStyle bodyStrong(Brightness brightness) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: UiColors.primary(brightness),
    );
  }
}
