import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  // Primary game UI hierarchy (titles/stats)
  static TextStyle get headline => const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 29,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      );

  static TextStyle get title => const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.45,
      );

  // Primary readable body font across the app.
  static TextStyle get body => const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get caption => const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get button => const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  // Strong contrast for stats / counters / level numbers.
  static TextStyle get statNumber => const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      );

  // Optional accent style for special badges only.
  static TextStyle get specialLabel => const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.8,
      );

  static TextStyle get sectionTitle => title.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get sectionSubtitle => caption;

  static TextStyle get cardTitle => title.copyWith(fontSize: 17);

  static TextStyle get chip => const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );

  static TextTheme get textTheme {
    const base = TextTheme();
    return base.copyWith(
      displayLarge: headline,
      headlineLarge: headline,
      titleLarge: title,
      titleMedium: title.copyWith(fontSize: 16),
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: button,
      labelMedium: caption,
      labelSmall: caption.copyWith(fontSize: 11),
    );
  }
}
