import 'package:flutter/material.dart';

/// Yamaha-flavored theme: deep blue primary, red accent (matches the YMSLI
/// deck: navy `#1B2A6B`-ish blue, Yamaha red `#E60012`).
class AppColors {
  const AppColors._();

  static const Color yamahaBlue = Color(0xFF1C2B5B);
  static const Color yamahaRed = Color(0xFFE60012);
  static const Color background = Color(0xFFF5F6FA);

  static const Color hot = Color(0xFFE53935);
  static const Color warm = Color(0xFFF9A825);
  static const Color cold = Color(0xFF42A5F5);

  static const Color statusNew = Color(0xFF42A5F5);
  static const Color statusFollowUp = Color(0xFFF9A825);
  static const Color statusClosedWon = Color(0xFF43A047);
  static const Color statusClosedLost = Color(0xFF9E9E9E);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.yamahaBlue,
      primary: AppColors.yamahaBlue,
      secondary: AppColors.yamahaRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.yamahaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yamahaRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.yamahaRed,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
