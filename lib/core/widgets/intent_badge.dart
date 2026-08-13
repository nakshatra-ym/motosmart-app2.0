import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../config/design.dart';
import 'document.dart';

/// The AI's verdict on a lead, as a stamp on the record.
///
/// This is the hackathon's mandatory "smart AI feature" surface, so it says who
/// judged: a stamped intent came from the model, and [UnclassifiedBadge] is what
/// an unjudged record shows.
class IntentBadge extends StatelessWidget {
  const IntentBadge({super.key, required this.intent, this.compact = false});

  final AiIntent intent;
  final bool compact;

  Color get _color => switch (intent) {
        // Hot is the stamp, warm the commercial field, cold the hologram —
        // the document world's own three registers.
        AiIntent.hot => Ds.alert,
        AiIntent.warm => Ds.caution,
        AiIntent.cold => Ds.info,
      };

  IconData get _icon => switch (intent) {
        AiIntent.hot => Icons.local_fire_department_outlined,
        AiIntent.warm => Icons.trending_up,
        AiIntent.cold => Icons.trending_down,
      };

  @override
  Widget build(BuildContext context) {
    return DocStamp(
      label: intent.name,
      color: _color,
      icon: _icon,
      // Only HOT is inked solid; the point of a stamp is that one state
      // dominates the page.
      filled: intent == AiIntent.hot,
      tilt: compact ? -0.02 : -0.035,
    );
  }
}

/// A record the model has not judged yet: an empty stamp box waiting for one.
class UnclassifiedBadge extends StatelessWidget {
  const UnclassifiedBadge({super.key, this.onTap, this.busy = false});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(Ds.rSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Ds.s2, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Ds.rSm),
          // Dashed-looking empty box: nothing has been stamped here yet.
          border: Border.all(
            color: Ds.lineStrong,
            width: 1.4,
            style: BorderStyle.solid,
          ),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: Ds.info,
                ),
              )
            else
              const Icon(Icons.approval_outlined, size: 11.5, color: Ds.inkMuted),
            const SizedBox(width: 4),
            Text(
              busy ? 'READING…' : 'NOT RATED',
              style: Ds.label(color: busy ? Ds.info : Ds.inkMuted)
                  .copyWith(fontSize: 10, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
    );
  }
}
