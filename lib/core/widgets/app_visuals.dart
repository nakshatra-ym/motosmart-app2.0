import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Atmospheric page backdrop — cool mist gradient instead of flat gray.
class AppPageBackground extends StatelessWidget {
  const AppPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3F6FC),
            AppColors.canvas,
            Color(0xFFDCE4F4),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Consistent icon treatment — tonal well with optional brand fill.
class AppIconWell extends StatelessWidget {
  const AppIconWell({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 22,
    this.color = AppColors.yamahaBlue,
    this.filled = false,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  Color.lerp(color, AppColors.brandInk, 0.28)!,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.16),
                  color.withValues(alpha: 0.06),
                ],
              ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(
          color: filled ? Colors.transparent : color.withValues(alpha: 0.14),
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: filled ? Colors.white : color,
      ),
    );
  }
}

/// Motospot wordmark + mark used on auth and branded surfaces.
class MotospotMark extends StatelessWidget {
  const MotospotMark({
    super.key,
    this.compact = false,
    this.light = false,
  });

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : AppColors.ink;
    final subtitleColor = light ? Colors.white70 : AppColors.inkMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWell(
          icon: Icons.two_wheeler_rounded,
          size: compact ? 56 : 76,
          iconSize: compact ? 26 : 34,
          filled: true,
          color: AppColors.yamahaBlue,
        ),
        SizedBox(height: compact ? 14 : 20),
        Text(
          'MOTOSPOT',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                fontSize: compact ? 22 : 28,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ride · Service · Deal',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: subtitleColor,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
