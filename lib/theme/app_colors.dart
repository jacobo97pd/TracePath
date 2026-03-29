import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Requested global palette
  static const Color primaryDark = Color(0xFF0B1C2C);
  static const Color primary = Color(0xFF162F45);
  static const Color accent = Color(0xFF00D1FF);
  static const Color accentSecondary = Color(0xFF7B61FF);
  static const Color success = Color(0xFF00E676);
  static const Color background = Color(0xFF0A1929);
  static const Color surface = Color(0xFF112240);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0B3C6);

  // Compatibility aliases used across the app.
  static const Color surfaceElevated = Color(0xFF173054);
  static const Color border = Color(0xFF24466A);
  static const Color softBorder = Color(0xFF1D3D5F);
  static const Color primaryStrong = accentSecondary;
  static const Color warning = Color(0xFFFFD166);
  static const Color danger = Color(0xFFFF6B7A);
  static const Color chipSelected = Color(0xFF1C3553);
  static const Color chipIdle = Color(0xFF122944);
  static const Color shadow = Color(0x55000000);
  static const Color glow = Color(0x4400D1FF);
}
