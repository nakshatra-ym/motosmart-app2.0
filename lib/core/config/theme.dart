import 'package:flutter/material.dart';

import 'design.dart';

/// Yamaha-flavored Material 3 theme (see [Ds] for the tokens).
///
/// The brand colours are binding — Yamaha deep blue carries actions and identity,
/// Yamaha red is reserved for urgency — and everything else is quiet: a near-white
/// ground, hairline borders, no filled surfaces competing with content.
///
/// [AppColors] is kept as the name the rest of the app already imports; every
/// value now resolves to a [Ds] role so there is one source of truth.
class AppColors {
  const AppColors._();

  static const Color yamahaBlue = Ds.brand;
  static const Color yamahaRed = Ds.alert;
  static const Color background = Ds.surface;

  /// Lead intent: urgent red, cautionary amber, informational blue.
  static const Color hot = Ds.alert;
  static const Color warm = Ds.caution;
  static const Color cold = Ds.info;

  static const Color statusNew = Ds.info;
  static const Color statusFollowUp = Ds.caution;
  static const Color statusClosedWon = Ds.positive;
  static const Color statusClosedLost = Ds.neutral;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Ds.brand,
      primary: Ds.brand,
      onPrimary: Colors.white,
      secondary: Ds.alert,
      onSecondary: Colors.white,
      surface: Ds.surfaceRaised,
      onSurface: Ds.ink,
      error: Ds.alert,
      brightness: Brightness.light,
    );

    final text = Ds.textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Ds.surface,
      fontFamily: Ds.family,
      textTheme: text,
      // Ripples on paper are wrong; the world's feedback is a crisp press.
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: const DividerThemeData(
        color: Ds.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Ds.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        iconTheme: const IconThemeData(color: Ds.ink, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Ds.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ds.rMd),
          side: const BorderSide(color: Ds.line),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Ds.surfaceRaised,
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.labelMedium?.copyWith(color: Ds.brand),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintStyle: text.bodyMedium?.copyWith(color: Ds.inkMuted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: Ds.alertDeep),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Ds.s4,
          vertical: Ds.s4,
        ),
        border: _fieldBorder(Ds.lineStrong),
        enabledBorder: _fieldBorder(Ds.lineStrong),
        focusedBorder: _fieldBorder(Ds.brand, width: 1.6),
        errorBorder: _fieldBorder(Ds.alert),
        focusedErrorBorder: _fieldBorder(Ds.alert, width: 1.6),
        disabledBorder: _fieldBorder(Ds.line),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Ds.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Ds.line,
          disabledForegroundColor: Ds.inkMuted,
          elevation: 0,
          minimumSize: const Size(0, Ds.tap),
          padding: const EdgeInsets.symmetric(horizontal: Ds.s5),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ds.rSm + 4),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Ds.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, Ds.tap),
          padding: const EdgeInsets.symmetric(horizontal: Ds.s5),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ds.rSm + 4),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Ds.brand,
          minimumSize: const Size(0, Ds.tap),
          padding: const EdgeInsets.symmetric(horizontal: Ds.s5),
          textStyle: text.labelLarge,
          side: const BorderSide(color: Ds.lineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ds.rSm + 4),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Ds.brand,
          minimumSize: const Size(0, Ds.tap),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ds.rSm),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Ds.brand,
        foregroundColor: Colors.white,
        elevation: 3,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ds.rMd),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Ds.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Ds.brand.withValues(alpha: 0.10),
        indicatorShape: const StadiumBorder(),
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelMedium?.copyWith(color: Ds.brand)
              : text.labelMedium?.copyWith(color: Ds.inkMuted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? Ds.brand : Ds.inkMuted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Ds.surfaceRaised,
        indicatorColor: Ds.brand.withValues(alpha: 0.10),
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: const IconThemeData(color: Ds.brand, size: 22),
        unselectedIconTheme: const IconThemeData(color: Ds.inkMuted, size: 22),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: Ds.brand),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: Ds.inkMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Ds.lineStrong),
        labelStyle: text.labelMedium!,
        padding: const EdgeInsets.symmetric(horizontal: Ds.s3, vertical: 7),
        shape: const StadiumBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Ds.ink,
        elevation: 2,
        contentTextStyle: text.bodyMedium?.copyWith(color: Ds.surface),
        actionTextColor: const Color(0xFF9CC0FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ds.rMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Ds.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ds.rMd),
          side: const BorderSide(color: Ds.lineStrong),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Ds.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: Ds.lineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Ds.rMd)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        iconColor: Ds.inkMuted,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Ds.brand,
        linearMinHeight: 3,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Ds.ink,
        unselectedLabelColor: Ds.inkMuted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: Ds.alert,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Ds.line,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Ds.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Ds.positive : Ds.line,
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ds.rSm + 4),
        borderSide: BorderSide(color: color, width: width),
      );
}
