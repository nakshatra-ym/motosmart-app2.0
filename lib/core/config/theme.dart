import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Motospot visual system — asphalt ink, signal blue, racing red.
///
/// Designed for a rider/dealer product: high contrast, athletic type,
/// and a cool atmospheric canvas. Red is reserved for primary actions;
/// teal marks AI / smart surfaces.
class AppColors {
  const AppColors._();

  /// Interactive / brand blue (vivid signal — not muddy navy).
  static const Color yamahaBlue = Color(0xFF1A45FF);

  /// Deep mark used for wordmarks and dark wells.
  static const Color brandInk = Color(0xFF070B14);

  /// Racing red — primary CTAs only.
  static const Color yamahaRed = Color(0xFFFF2D2D);

  /// AI / smart accent.
  static const Color accent = Color(0xFF00BFA6);

  /// Legacy alias.
  static const Color background = canvas;

  static const Color canvas = Color(0xFFE7ECF6);
  static const Color canvasDeep = Color(0xFFD3DBEC);
  static const Color surface = Color(0xFFFBFCFE);
  static const Color surfaceMuted = Color(0xFFEEF2FA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF070B14);
  static const Color inkMuted = Color(0xFF4A5568);
  static const Color inkFaint = Color(0xFF8A94A8);

  static const Color border = Color(0xFFD7DEEC);
  static const Color borderStrong = Color(0xFFB8C2D9);

  static const Color hot = Color(0xFFE11D48);
  static const Color warm = Color(0xFFF59E0B);
  static const Color cold = Color(0xFF3B82F6);

  static const Color statusNew = Color(0xFF3B82F6);
  static const Color statusFollowUp = Color(0xFFF59E0B);
  static const Color statusClosedWon = Color(0xFF10B981);
  static const Color statusClosedLost = Color(0xFF8A94A8);
}

class AppTheme {
  const AppTheme._();

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.brandInk.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.yamahaBlue.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static ThemeData get light {
    final sora = GoogleFonts.soraTextTheme();
    final manrope = GoogleFonts.manropeTextTheme();

    final textTheme = manrope
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          displaySmall: sora.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            height: 1.1,
            color: AppColors.ink,
          ),
          headlineMedium: sora.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
            height: 1.15,
            color: AppColors.ink,
            fontSize: 28,
          ),
          headlineSmall: sora.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            height: 1.2,
            color: AppColors.ink,
            fontSize: 22,
          ),
          titleLarge: sora.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: AppColors.ink,
            fontSize: 18,
          ),
          titleMedium: sora.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppColors.ink,
            fontSize: 16,
          ),
          titleSmall: sora.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.ink,
            fontSize: 14,
          ),
          bodyLarge: manrope.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: manrope.bodyMedium?.copyWith(
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
          bodySmall: manrope.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.45,
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w500,
          ),
          labelLarge: sora.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            fontSize: 14,
          ),
          labelMedium: manrope.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
            letterSpacing: 0.2,
          ),
          labelSmall: manrope.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaint,
            letterSpacing: 0.35,
            fontSize: 11,
          ),
        );

    final colorScheme = ColorScheme.light(
      primary: AppColors.yamahaBlue,
      onPrimary: Colors.white,
      secondary: AppColors.yamahaRed,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
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
        backgroundColor: AppColors.surface.withValues(alpha: 0.92),
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 18,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.yamahaBlue,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: selected ? AppColors.yamahaBlue : AppColors.inkFaint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? Colors.white : AppColors.inkFaint,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.yamahaBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.hot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.hot, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yamahaRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.yamahaRed.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yamahaBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.surfaceElevated,
          side: const BorderSide(color: AppColors.borderStrong, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.yamahaBlue,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.yamahaRed,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.yamahaBlue.withValues(alpha: 0.14),
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandInk,
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
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.yamahaBlue.withValues(alpha: 0.12);
            }
            return AppColors.surfaceElevated;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.yamahaBlue;
            }
            return AppColors.inkMuted;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.borderStrong)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
