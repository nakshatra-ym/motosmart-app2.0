import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Lightweight shimmer — no packages, single AnimationController.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.4 + 2.8 * t, 0),
              end: Alignment(-0.2 + 2.8 * t, 0),
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.18),
                Colors.white.withValues(alpha: 0.04),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 10,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.glassBorder),
      ),
    );
  }
}

/// Default page loading skeleton used by [AsyncValueWidget].
class ShimmerPageSkeleton extends StatelessWidget {
  const ShimmerPageSkeleton({super.key, this.cards = 4});

  final int cards;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        itemCount: cards,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 96, height: 10, radius: 6),
                const SizedBox(height: 12),
                const ShimmerBox(width: 180, height: 28, radius: 10),
                const SizedBox(height: 8),
                const ShimmerBox(width: 240, height: 12, radius: 6),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Container(
            height: 88,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 44, height: 44, radius: 14),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(width: 140, height: 12),
                      SizedBox(height: 10),
                      ShimmerBox(width: 200, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Soft branded pulse for inline / button loading (replaces harsh spinners visually).
class SoftLoader extends StatefulWidget {
  const SoftLoader({
    super.key,
    this.size = 22,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  State<SoftLoader> createState() => _SoftLoaderState();
}

class _SoftLoaderState extends State<SoftLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ArcPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.25);
    canvas.drawArc(rect.deflate(stroke), 0, 6.28, false, paint);

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    final start = progress * 6.28;
    canvas.drawArc(rect.deflate(stroke), start, 1.6, false, active);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
