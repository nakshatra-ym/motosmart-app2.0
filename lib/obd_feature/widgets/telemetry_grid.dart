import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../models/obd_reading.dart';

/// Live OBD cluster — gauges and bars that animate as Bluetooth readings arrive.
class TelemetryGrid extends StatelessWidget {
  final ObdReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 360;
        final gauges = [
          _LiveGauge(
            label: 'RPM',
            value: reading.rpm.toDouble(),
            max: 8000,
            display: reading.rpm.toString(),
            unit: 'rev/min',
            color: AppColors.yamahaBlue,
          ),
          _LiveGauge(
            label: 'Speed',
            value: reading.speedKph,
            max: 160,
            display: reading.speedKph.toStringAsFixed(0),
            unit: 'km/h',
            color: AppColors.accent,
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(child: gauges[0]),
                  const SizedBox(width: 12),
                  Expanded(child: gauges[1]),
                ],
              )
            else ...[
              gauges[0],
              const SizedBox(height: 12),
              gauges[1],
            ],
            const SizedBox(height: 8),
            _LiveBar(
              label: 'Coolant',
              valueLabel: '${reading.coolantTempC.toStringAsFixed(1)}°C',
              progress: (reading.coolantTempC / 120).clamp(0.0, 1.0),
              color: reading.coolantTempC > 100
                  ? AppColors.hot
                  : reading.coolantTempC > 90
                      ? AppColors.warm
                      : AppColors.yamahaBlue,
              icon: Icons.thermostat,
            ),
            _LiveBar(
              label: 'Battery',
              valueLabel: '${reading.batteryVoltage.toStringAsFixed(2)} V',
              progress: ((reading.batteryVoltage - 10) / 5).clamp(0.0, 1.0),
              color: reading.batteryVoltage < 12 ? AppColors.hot : AppColors.statusClosedWon,
              icon: Icons.battery_full,
            ),
            _LiveBar(
              label: 'Throttle',
              valueLabel: '${reading.throttlePositionPct.toStringAsFixed(0)}%',
              progress: (reading.throttlePositionPct / 100).clamp(0.0, 1.0),
              color: AppColors.violet,
              icon: Icons.tune,
            ),
            _LiveBar(
              label: 'Fuel',
              valueLabel: '${reading.fuelLevelPct.toStringAsFixed(0)}%',
              progress: (reading.fuelLevelPct / 100).clamp(0.0, 1.0),
              color: AppColors.magenta,
              icon: Icons.local_gas_station,
              showDivider: false,
            ),
          ],
        );
      },
    );
  }
}

class _LiveGauge extends StatefulWidget {
  const _LiveGauge({
    required this.label,
    required this.value,
    required this.max,
    required this.display,
    required this.unit,
    required this.color,
  });

  final String label;
  final double value;
  final double max;
  final String display;
  final String unit;
  final Color color;

  @override
  State<_LiveGauge> createState() => _LiveGaugeState();
}

class _LiveGaugeState extends State<_LiveGauge> {
  late double _from;
  late double _to;

  double get _target => (widget.value / widget.max).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _from = _target;
    _to = _target;
  }

  @override
  void didUpdateWidget(covariant _LiveGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.max != widget.max) {
      _from = _to;
      _to = _target;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey(_to),
      tween: Tween(begin: _from, end: _to),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, anim, _) {
        return SizedBox(
          height: 148,
          child: CustomPaint(
            painter: _ArcPainter(progress: anim, color: widget.color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.label, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      widget.display,
                      key: ValueKey(widget.display),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(widget.unit, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final radius = math.min(size.width, size.height) * 0.42;
    const start = -math.pi * 0.85;
    const sweep = math.pi * 1.7;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, start, sweep, false, track);
    canvas.drawArc(rect, start, sweep * progress, false, fill);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _LiveBar extends StatefulWidget {
  const _LiveBar({
    required this.label,
    required this.valueLabel,
    required this.progress,
    required this.color,
    required this.icon,
    this.showDivider = true,
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color color;
  final IconData icon;
  final bool showDivider;

  @override
  State<_LiveBar> createState() => _LiveBarState();
}

class _LiveBarState extends State<_LiveBar> {
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.progress;
    _to = widget.progress;
  }

  @override
  void didUpdateWidget(covariant _LiveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _from = _to;
      _to = widget.progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: widget.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.label, style: theme.textTheme.labelSmall),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: Text(
                            widget.valueLabel,
                            key: ValueKey(widget.valueLabel),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      key: ValueKey(_to),
                      tween: Tween(begin: _from, end: _to),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            color: widget.color,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.showDivider)
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
      ],
    );
  }
}
