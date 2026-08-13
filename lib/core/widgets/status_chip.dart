import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../config/design.dart';

/// A lead's status, set as a form's status field rather than a rounded pill:
/// square, ruled, and colour-coded to the same registers the rest of the
/// document world uses.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dense = false});

  final LeadStatus status;
  final bool dense;

  Color get _color => switch (status) {
        LeadStatus.newLead => Ds.info,
        LeadStatus.followUp => Ds.caution,
        LeadStatus.closedWon => Ds.positive,
        LeadStatus.closedLost => Ds.neutral,
      };

  /// Colour alone never carries the state — each status keeps a mark, so it
  /// survives a colour-blind reader and a bleached phone screen outdoors.
  IconData get _icon => switch (status) {
        LeadStatus.newLead => Icons.fiber_new_outlined,
        LeadStatus.followUp => Icons.schedule,
        LeadStatus.closedWon => Icons.verified_outlined,
        LeadStatus.closedLost => Icons.block_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : Ds.s2,
        vertical: dense ? 2 : 3.5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Ds.rSm),
        border: Border.all(color: _color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: dense ? 10.5 : 12, color: _color),
          const SizedBox(width: 4),
          Text(
            status.label.toUpperCase(),
            style: Ds.label(color: _color)
                .copyWith(fontSize: dense ? 9.5 : 10.5, letterSpacing: 0.7),
          ),
        ],
      ),
    );
  }
}
