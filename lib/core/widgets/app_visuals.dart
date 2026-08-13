import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Dark mesh-gradient stage used behind every premium surface.
class AppPageBackground extends StatelessWidget {
  const AppPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.canvasDeep)),
        Positioned(
          top: -120,
          left: -80,
          child: _Blob(color: AppColors.yamahaBlue.withValues(alpha: 0.38), size: 340),
        ),
        Positioned(
          top: 180,
          right: -100,
          child: _Blob(color: AppColors.magenta.withValues(alpha: 0.22), size: 300),
        ),
        Positioned(
          bottom: -80,
          left: 40,
          child: _Blob(color: AppColors.violet.withValues(alpha: 0.2), size: 280),
        ),
        Positioned(
          bottom: 120,
          right: -40,
          child: _Blob(color: AppColors.accent.withValues(alpha: 0.12), size: 220),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.canvasDeep.withValues(alpha: 0.55),
                  AppColors.canvasDeep,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Frosted glass panel — Aceternity / Magic UI feel in Flutter.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius,
    this.glow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppTheme.radiusLg);

    Widget panel = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              if (glow != null)
                BoxShadow(color: glow!.withValues(alpha: 0.28), blurRadius: 28, spreadRadius: -6),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      panel = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: radius, child: panel),
      );
    }
    return panel;
  }
}

/// Staggered fade/slide entrance for section wow.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay.inMilliseconds.clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated metric counter for bento tiles.
class AnimatedMetric extends StatelessWidget {
  const AnimatedMetric({
    super.key,
    required this.value,
    this.style,
  });

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(
          '${v.round()}',
          style: style ??
              Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.6,
                  ),
        );
      },
    );
  }
}

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
                colors: [color, Color.lerp(color, AppColors.magenta, 0.35)!],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(
          color: filled ? Colors.white.withValues(alpha: 0.12) : color.withValues(alpha: 0.28),
        ),
        boxShadow: filled
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8))]
            : null,
      ),
      child: Icon(icon, size: iconSize, color: filled ? Colors.white : color),
    );
  }
}

class MotospotMark extends StatelessWidget {
  const MotospotMark({super.key, this.compact = false, this.light = true});

  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconWell(
          icon: Icons.two_wheeler_rounded,
          size: compact ? 56 : 80,
          iconSize: compact ? 26 : 36,
          filled: true,
        ),
        SizedBox(height: compact ? 14 : 22),
        Text(
          'Motospot',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
                fontSize: compact ? 20 : 24,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Dealer intelligence',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
                letterSpacing: 0.1,
              ),
        ),
      ],
    );
  }
}

/// Soft floating orb used as decorative motion accent.
class FloatingOrb extends StatefulWidget {
  const FloatingOrb({
    super.key,
    required this.color,
    this.size = 12,
  });

  final Color color;
  final double size;

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -6 * _c.value),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: 0.55), blurRadius: 14, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
