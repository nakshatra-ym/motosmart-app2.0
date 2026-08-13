import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Motospot dark-first system — Product Hunt / hackathon wow palette.
///
/// Near-black canvas, electric blue + magenta mesh accents, glass surfaces.
/// [yamahaBlue] / [yamahaRed] names kept for call-site compatibility.
class AppColors {
  const AppColors._();

  static const Color yamahaBlue = Color(0xFF5B8CFF);
  static const Color brandInk = Color(0xFF05060A);
  static const Color yamahaRed = Color(0xFFFF3B5C);
  static const Color accent = Color(0xFF2EE6A6);
  static const Color violet = Color(0xFFA78BFA);
  static const Color magenta = Color(0xFFFF4D9E);

  static const Color background = canvas;
  static const Color canvas = Color(0xFF07090F);
  static const Color canvasDeep = Color(0xFF03040A);
  static const Color surface = Color(0xFF0E121B);
  static const Color surfaceMuted = Color(0xFF151B28);
  static const Color surfaceElevated = Color(0xFF121826);

  static const Color glass = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x28FFFFFF);
  static const Color glassHighlight = Color(0x1AFFFFFF);

  static const Color ink = Color(0xFFF4F6FB);
  static const Color inkMuted = Color(0xFF9AA3B8);
  static const Color inkFaint = Color(0xFF6B7388);

  static const Color border = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x33FFFFFF);

  static const Color hot = Color(0xFFFF4D6D);
  static const Color warm = Color(0xFFFFB020);
  static const Color cold = Color(0xFF5B8CFF);

  static const Color statusNew = Color(0xFF5B8CFF);
  static const Color statusFollowUp = Color(0xFFFFB020);
  static const Color statusClosedWon = Color(0xFF2EE6A6);
  static const Color statusClosedLost = Color(0xFF6B7388);
}

class AppTheme {
  const AppTheme._();

  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 32,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: AppColors.yamahaBlue.withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowBlue => [
        BoxShadow(
          color: AppColors.yamahaBlue.withValues(alpha: 0.35),
          blurRadius: 28,
          spreadRadius: -4,
        ),
      ];

  static ThemeData get light => dark; // app is dark-first

  static ThemeData get dark {
    final baseText = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseText.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink).copyWith(
          displaySmall: baseText.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.15,
            color: AppColors.ink,
            fontSize: 34,
          ),
          headlineMedium: baseText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
            color: AppColors.ink,
            fontSize: 28,
          ),
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            height: 1.25,
            color: AppColors.ink,
            fontSize: 22,
          ),
          titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.ink,
            fontSize: 18,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            color: AppColors.ink,
            fontSize: 16,
          ),
          titleSmall: baseText.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            fontSize: 14,
          ),
          bodyLarge: baseText.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.5,
            color: AppColors.ink,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: baseText.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.45,
            color: AppColors.inkFaint,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            fontSize: 14,
          ),
          labelMedium: baseText.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
            letterSpacing: 0.1,
          ),
          labelSmall: baseText.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.inkFaint,
            letterSpacing: 0.2,
            fontSize: 11,
          ),
        );

    final colorScheme = ColorScheme.dark(
      primary: AppColors.yamahaBlue,
      onPrimary: Colors.white,
      secondary: AppColors.yamahaRed,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: AppColors.brandInk,
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
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      dividerColor: AppColors.border,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.inkMuted, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 18,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xE60A0D14),
        elevation: 0,
        height: 72,
        indicatorColor: AppColors.yamahaBlue.withValues(alpha: 0.22),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.ink : AppColors.inkFaint,
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
        color: AppColors.glass,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.yamahaBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.hot),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.hot, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yamahaRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.yamahaRed.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yamahaBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: const Color(0x0DFFFFFF),
          side: const BorderSide(color: AppColors.glassBorder),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
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
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x14FFFFFF),
        selectedColor: AppColors.yamahaBlue.withValues(alpha: 0.22),
        side: const BorderSide(color: AppColors.glassBorder),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.inkMuted,
        textColor: AppColors.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0E121B),
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.inkFaint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A2030),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.yamahaBlue),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.yamahaRed, textColor: Colors.white),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.yamahaBlue.withValues(alpha: 0.22);
            }
            return const Color(0x14FFFFFF);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.ink;
            return AppColors.inkMuted;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.glassBorder)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
