import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Motospot design tokens — light premium Yamaha Motospot.
///
/// Brand anchors stay navy + red. Surfaces, ink, and borders carry the
/// refined SaaS feel; red is reserved for primary CTAs.
class AppColors {
  const AppColors._();

  // Brand
  static const Color yamahaBlue = Color(0xFF152447);
  static const Color yamahaRed = Color(0xFFE10600);

  /// Legacy alias — prefer [canvas].
  static const Color background = canvas;

  // Surfaces
  static const Color canvas = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1F7);

  // Ink
  static const Color ink = Color(0xFF0F172A);
  static const Color inkMuted = Color(0xFF5B657A);
  static const Color inkFaint = Color(0xFF8B93A7);

  // Borders
  static const Color border = Color(0xFFE4E8F0);
  static const Color borderStrong = Color(0xFFD0D5E0);

  // Intent / status
  static const Color hot = Color(0xFFD32F2F);
  static const Color warm = Color(0xFFE6A010);
  static const Color cold = Color(0xFF2F80ED);

  static const Color statusNew = Color(0xFF2F80ED);
  static const Color statusFollowUp = Color(0xFFE6A010);
  static const Color statusClosedWon = Color(0xFF2E9B5A);
  static const Color statusClosedLost = Color(0xFF8B93A7);
}

class AppTheme {
  const AppTheme._();

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;

  static ThemeData get light {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseText
        .apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          displaySmall: baseText.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.15,
            color: AppColors.ink,
          ),
          headlineMedium: baseText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.2,
            color: AppColors.ink,
          ),
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.25,
            color: AppColors.ink,
          ),
          titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.ink,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
          titleSmall: baseText.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: baseText.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.45,
            color: AppColors.ink,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            fontSize: 14.5,
            height: 1.45,
            color: AppColors.ink,
          ),
          bodySmall: baseText.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.4,
            color: AppColors.inkMuted,
          ),
          labelLarge: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelMedium: baseText.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
          ),
          labelSmall: baseText.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.inkFaint,
            letterSpacing: 0.2,
          ),
        );

    final colorScheme = ColorScheme.light(
      primary: AppColors.yamahaBlue,
      onPrimary: Colors.white,
      secondary: AppColors.yamahaRed,
      onSecondary: Colors.white,
      tertiary: AppColors.yamahaBlue,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerHighest: AppColors.surfaceMuted,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
      error: AppColors.hot,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      dividerColor: AppColors.border,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.inkMuted, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.yamahaBlue.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.yamahaBlue : AppColors.inkFaint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.yamahaBlue : AppColors.inkFaint,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.ink.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.yamahaBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.hot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.hot, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yamahaRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.yamahaRed.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yamahaBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.yamahaBlue,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.yamahaRed,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.yamahaBlue.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.inkMuted,
        textColor: AppColors.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.yamahaBlue,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.yamahaRed,
        textColor: Colors.white,
      ),
      refreshIndicatorTheme: const RefreshIndicatorThemeData(
        color: AppColors.yamahaBlue,
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
