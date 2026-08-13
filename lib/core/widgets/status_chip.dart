import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../config/theme.dart';

/// Colored chip for a [LeadStatus] — reused everywhere a lead is listed.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final LeadStatus status;

  Color get _color => switch (status) {
        LeadStatus.newLead => AppColors.statusNew,
        LeadStatus.followUp => AppColors.statusFollowUp,
        LeadStatus.closedWon => AppColors.statusClosedWon,
        LeadStatus.closedLost => AppColors.statusClosedLost,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.28)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
