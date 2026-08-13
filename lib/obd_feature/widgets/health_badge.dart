import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../models/obd_reading.dart';

class HealthBadge extends StatelessWidget {
  final HealthResult health;

  const HealthBadge({super.key, required this.health});

  Color _color() => switch (health.level) {
        HealthLevel.green => AppColors.statusClosedWon,
        HealthLevel.amber => AppColors.warm,
        HealthLevel.red => AppColors.hot,
      };

  String _label() => switch (health.level) {
        HealthLevel.green => 'All systems normal',
        HealthLevel.amber => 'Attention needed',
        HealthLevel.red => 'Urgent — service recommended',
      };

  IconData _icon() => switch (health.level) {
        HealthLevel.green => Icons.check_circle,
        HealthLevel.amber => Icons.warning_amber_rounded,
        HealthLevel.red => Icons.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Row(
                  children: [
                    Icon(_icon(), color: color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (health.reasons.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              health.reasons.first,
                              style: TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Rule-based · SAE diagnostic standards',
                            style: TextStyle(
                              color: AppColors.inkFaint,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
