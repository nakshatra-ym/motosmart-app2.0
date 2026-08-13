import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../config/theme.dart';

/// The AI triage on a service request: how urgent it is, and which system it is
/// about. Shown wherever a ticket is listed so the desk can work the dangerous
/// ones first.
///
/// Renders nothing when triage did not run — an unclassified ticket shows no
/// chips rather than a misleading "Normal".
class TicketAiChips extends StatelessWidget {
  const TicketAiChips({
    super.key,
    required this.priority,
    required this.category,
    this.compact = false,
  });

  final TicketPriority? priority;
  final TicketCategory? category;

  /// Drops the category chip, for tight list rows.
  final bool compact;

  static Color colorFor(TicketPriority priority) => switch (priority) {
        // Urgent means "stop riding" — it gets the same red as a hot lead.
        TicketPriority.urgent => AppColors.hot,
        TicketPriority.high => AppColors.warm,
        TicketPriority.normal => AppColors.yamahaBlue,
        TicketPriority.low => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (priority != null)
        _Chip(
          label: priority == TicketPriority.urgent
              ? 'Urgent'
              : '${priority!.label} priority',
          color: colorFor(priority!),
          icon: priority == TicketPriority.urgent ? Icons.warning_amber : null,
          filled: priority == TicketPriority.urgent,
        ),
      if (category != null && !compact)
        _Chip(label: category!.label, color: Colors.black54),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.9 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
