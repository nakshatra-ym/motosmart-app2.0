import 'package:flutter/material.dart';

import '../../core/config/design.dart';
import '../models/obd_reading.dart';

/// The inspection verdict, set as a certificate's result band — the way a PUC
/// certificate states pass or fail across the top of the sheet.
///
/// The provenance line stays: this verdict comes from the on-device rule engine
/// against SAE codes, not from a model, and the interface says which.
class HealthBadge extends StatelessWidget {
  final HealthResult health;

  const HealthBadge({super.key, required this.health});

  Color _color() => switch (health.level) {
        HealthLevel.green => Ds.positive,
        HealthLevel.amber => Ds.caution,
        HealthLevel.red => Ds.alert,
      };

  String _label() => switch (health.level) {
        HealthLevel.green => 'All systems normal',
        HealthLevel.amber => 'Attention needed',
        HealthLevel.red => 'Service recommended',
      };

  String _verdict() => switch (health.level) {
        HealthLevel.green => 'PASS',
        HealthLevel.amber => 'ADVISORY',
        HealthLevel.red => 'FAIL',
      };

  IconData _icon() => switch (health.level) {
        HealthLevel.green => Icons.verified_outlined,
        HealthLevel.amber => Icons.error_outline,
        HealthLevel.red => Icons.report_problem_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final text = Theme.of(context).textTheme;
    final failing = health.level != HealthLevel.green;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Ds.rMd),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The result band: the verdict word, inked, as a stamp across the top.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Ds.s3,
              vertical: Ds.s2,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Ds.rMd - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(_icon(), size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _verdict(),
                  style: Ds.label(color: Colors.white)
                      .copyWith(fontSize: 11, letterSpacing: 1.4),
                ),
                const Spacer(),
                Text(
                  'RULE-BASED · SAE',
                  style: Ds.label(color: Colors.white.withValues(alpha: 0.85))
                      .copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Ds.s3 + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(),
                  style: text.titleMedium?.copyWith(
                    color: failing ? color : Ds.ink,
                  ),
                ),
                if (health.reasons.isNotEmpty) ...[
                  const SizedBox(height: Ds.s2),
                  // Every reason, not only the first: a rider deciding whether
                  // to ride needs all of them.
                  for (final reason in health.reasons)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 3,
                            margin: const EdgeInsets.only(top: 7, right: 7),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(reason, style: text.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
