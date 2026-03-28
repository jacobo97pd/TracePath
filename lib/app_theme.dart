import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double page = 16;
  static const double section = 12;
  static const double cardRadius = 22;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const fg = Color(0xFFF2F6FF);
    const subtle = Color(0xFF9FB0CE);
    const border = Color(0xFF334155);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3E79FF),
        onPrimary: Colors.white,
        secondary: Color(0xFF3E79FF),
        surface: Color(0xFF1E293B),
        onSurface: fg,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: fg,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: fg,
        textColor: fg,
      ),
      dividerColor: border,
      iconTheme: const IconThemeData(color: fg),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: fg, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: subtle),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F172A),
        selectedItemColor: Color(0xFF7EA9FF),
        unselectedItemColor: Color(0xFF7D8CA8),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF1E293B),
        disabledColor: Color(0xFF212A39),
        selectedColor: Color(0xFF1D2F57),
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: fg),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: const BorderSide(color: border),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const bg = Color(0xFF0F172A);
    const surface = Color(0xFF1E293B);
    const fg = Color(0xFFEAEAEA);
    const subtle = Color(0xFFB6B6B6);
    const border = Color(0xFF334155);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3E79FF),
        onPrimary: Colors.white,
        secondary: Color(0xFF3E79FF),
        surface: surface,
        onSurface: fg,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: fg,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: fg,
        textColor: fg,
      ),
      dividerColor: border,
      iconTheme: const IconThemeData(color: fg),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: fg, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: subtle),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: Color(0xFF7EA9FF),
        unselectedItemColor: Color(0xFF7D8CA8),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: surface,
        disabledColor: Color(0xFF222226),
        selectedColor: Color(0xFF242428),
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: fg),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}
