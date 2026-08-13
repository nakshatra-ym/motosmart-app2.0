import 'package:flutter/material.dart';

/// The design language: **quiet, modern, Material 3**.
///
/// Restrained by intent — a near-white ground, one deep blue that carries every
/// action, and colour spent only where it means something (a lead's temperature,
/// a service verdict, an overdue date). Emphasis comes from weight and space, not
/// from filling surfaces with colour.
///
/// Light, decided from the scene rather than habit: a salesperson reads this at
/// arm's length on a bright showroom floor, and an owner reads it outdoors next
/// to a bike. A dark surface loses both.
class Ds {
  const Ds._();

  // ---------------------------------------------------------------- colour
  /// The page. Barely-tinted white, cool rather than cream.
  static const Color surface = Color(0xFFF7F8FA);

  /// Cards and sheets sitting on the page.
  static const Color surfaceRaised = Color(0xFFFFFFFF);

  /// A recessed band for grouped content (filters, headers, quiet rows).
  static const Color surfaceSunken = Color(0xFFEFF1F5);

  /// Text, in three registers.
  static const Color ink = Color(0xFF11161C);
  static const Color inkSoft = Color(0xFF474E58);
  static const Color inkMuted = Color(0xFF737C88);

  /// Hairlines. Cool grey, low contrast, 1dp.
  static const Color line = Color(0xFFE2E6EC);
  static const Color lineStrong = Color(0xFFCED4DD);

  /// Yamaha deep blue — the one colour that carries actions and identity.
  static const Color brand = Color(0xFF16295E);
  static const Color brandDeep = Color(0xFF0C1838);

  /// A lighter blue for informational states, so brand blue stays actionable.
  static const Color info = Color(0xFF2C64D4);

  /// Yamaha red. Urgency and destruction only — never decoration.
  static const Color alert = Color(0xFFE0000F);
  static const Color alertDeep = Color(0xFF9C000B);

  /// Warning and success.
  static const Color caution = Color(0xFFB57500);
  static const Color positive = Color(0xFF17754A);

  /// Finished and not celebrated.
  static const Color neutral = Color(0xFF7A828E);

  /// A colour's own quiet background, for chips and status rows.
  static Color wash(Color c) => Color.alphaBlend(c.withValues(alpha: 0.09), surfaceRaised);

  // ------------------------------------------------------------ dimensions
  /// Material 3's softer geometry, applied consistently.
  static const double rSm = 8;
  static const double rMd = 14;
  static const double rLg = 20;
  static const double rXl = 28;
  static const double rPill = 999;

  /// One spacing rhythm for the whole app.
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;

  /// Minimum touch target, per Material.
  static const double tap = 48;

  // ------------------------------------------------------------ responsive
  // Material's window size classes. Layout switches on these rather than
  // stretching one composition across a tablet.
  static const double compactMax = 600;
  static const double mediumMax = 840;

  /// Content stops growing and centres instead of running the full width.
  static const double readingMax = 720;
  static const double formMax = 460;

  static bool isCompact(BuildContext c) =>
      MediaQuery.sizeOf(c).width < compactMax;
  static bool isExpanded(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= mediumMax;

  /// Page padding that grows with the window.
  static EdgeInsets pagePad(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w >= mediumMax) return const EdgeInsets.fromLTRB(s8, s6, s8, s8);
    if (w >= compactMax) return const EdgeInsets.fromLTRB(s6, s5, s6, s6);
    return const EdgeInsets.fromLTRB(s4, s4, s4, s5);
  }

  // ----------------------------------------------------------------- depth
  /// A real offset and a soft blur, tinted with the ink rather than pure black.
  static List<BoxShadow> lift(double y) => [
        BoxShadow(
          color: const Color(0xFF0C1838).withValues(alpha: 0.07),
          offset: Offset(0, y),
          blurRadius: y * 3,
          spreadRadius: -y * 0.4,
        ),
      ];

  // ------------------------------------------------------------------ type
  static const String family = 'Archivo';

  static List<FontVariation> _axes(double weight, [double width = 100]) => [
        FontVariation('wght', weight),
        FontVariation('wdth', width),
      ];

  static const FontFeature _tabular = FontFeature.tabularFigures();

  /// Figures in a column: prices, odometer, counts, telemetry. Tabular so digits
  /// do not shift sideways between rows or as a live value updates.
  static TextStyle figure(double size, {double weight = 600, Color color = ink}) =>
      TextStyle(
        fontFamily: family,
        fontVariations: _axes(weight),
        fontSize: size,
        height: 1.1,
        letterSpacing: -0.2,
        color: color,
        fontFeatures: const [_tabular],
      );

  /// A small caps label above a value, or on a chip.
  static TextStyle label({Color color = inkMuted, double size = 11}) => TextStyle(
        fontFamily: family,
        fontVariations: _axes(620),
        fontSize: size,
        height: 1.15,
        letterSpacing: 0.5,
        color: color,
      );

  /// The Material type scale in this face. Screens use theme roles.
  static TextTheme textTheme() {
    TextStyle s(double size, double weight, double height, {double tracking = 0}) =>
        TextStyle(
          fontFamily: family,
          fontVariations: _axes(weight),
          fontSize: size,
          height: height,
          letterSpacing: tracking,
          color: ink,
        );

    return TextTheme(
      // Tight, slightly negative tracking at display sizes — the modern register.
      displayLarge: s(44, 680, 1.04, tracking: -1.2),
      displayMedium: s(36, 680, 1.06, tracking: -0.9),
      displaySmall: s(30, 660, 1.1, tracking: -0.7),
      headlineLarge: s(26, 640, 1.16, tracking: -0.5),
      headlineMedium: s(22, 640, 1.2, tracking: -0.4),
      headlineSmall: s(19, 620, 1.24, tracking: -0.25),
      titleLarge: s(17, 600, 1.3, tracking: -0.15),
      titleMedium: s(15, 580, 1.34),
      titleSmall: s(13.5, 580, 1.34),
      bodyLarge: s(15.5, 400, 1.5).copyWith(color: inkSoft),
      bodyMedium: s(14, 400, 1.5).copyWith(color: inkSoft),
      bodySmall: s(12.5, 420, 1.45).copyWith(color: inkMuted),
      labelLarge: s(14, 600, 1.2, tracking: 0.1),
      labelMedium: s(12.5, 600, 1.2, tracking: 0.2),
      labelSmall: s(11, 600, 1.15, tracking: 0.4).copyWith(color: inkMuted),
    );
  }
}
