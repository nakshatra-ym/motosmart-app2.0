import 'package:flutter/material.dart';
import '../models/obd_reading.dart';

class HealthBadge extends StatelessWidget {
  final HealthResult health;

  const HealthBadge({super.key, required this.health});

  Color _color() => switch (health.level) {
        HealthLevel.green => const Color(0xFF2E7D32),
        HealthLevel.amber => const Color(0xFFF9A825),
        HealthLevel.red => const Color(0xFFC62828),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(_icon(), color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (health.reasons.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    health.reasons.first,
                    style: TextStyle(color: color.withOpacity(0.85), fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Rule-based · SAE diagnostic standards',
                  style: TextStyle(
                    color: color.withOpacity(0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
