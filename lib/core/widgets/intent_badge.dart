import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../config/theme.dart';

/// The "smart AI feature" badge (HOT/WARM/COLD) — this is the hackathon's
/// mandatory "at least one smart AI feature in the product demo" surface.
class IntentBadge extends StatelessWidget {
  const IntentBadge({super.key, required this.intent, this.compact = false});

  final AiIntent intent;
  final bool compact;

  Color get _color => switch (intent) {
        AiIntent.hot => AppColors.hot,
        AiIntent.warm => AppColors.warm,
        AiIntent.cold => AppColors.cold,
      };

  IconData get _icon => switch (intent) {
        AiIntent.hot => Icons.whatshot,
        AiIntent.warm => Icons.thermostat,
        AiIntent.cold => Icons.ac_unit,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            intent.name.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill shown while [AiClassifyService] / the AI badge hasn't been
/// generated yet, with a tap target to trigger classification.
class UnclassifiedBadge extends StatelessWidget {
  const UnclassifiedBadge({super.key, this.onTap, this.busy = false});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.auto_awesome, size: 14),
            const SizedBox(width: 4),
            Text(
              busy ? 'Classifying…' : 'AI classify',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
