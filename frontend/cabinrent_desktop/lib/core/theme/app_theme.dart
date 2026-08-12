import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const forest = Color(0xFF173F35);
  static const moss = Color(0xFF477A65);
  static const sand = Color(0xFFF2E8D5);
  static const ink = Color(0xFF17201D);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
      primary: forest,
      secondary: moss,
      surface: const Color(0xFFFAFBF8),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F6F2),
      fontFamily: 'Segoe UI',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7DED9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7DED9)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E7E3)),
        ),
      ),
    );
  }
}
