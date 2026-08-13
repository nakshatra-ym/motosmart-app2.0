import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/design.dart';
import '../../../core/widgets/document.dart';
import '../../../core/widgets/intent_badge.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/enums.dart';
import '../../../models/lead.dart';
import '../data/leads_providers.dart';

/// One enquiry, filed.
///
/// The spine carries the AI's read of the lead, so scanning the list down its
/// left edge tells a salesperson which enquiries are worth a call before they
/// read a single name.
class LeadCard extends ConsumerWidget {
  const LeadCard({super.key, required this.lead, required this.onTap});

  final Lead lead;
  final VoidCallback onTap;

  Color get _spine => switch (lead.aiIntent) {
        AiIntent.hot => Ds.alert,
        AiIntent.warm => Ds.caution,
        AiIntent.cold => Ds.info,
        null => Ds.line,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final bikeModels = ref.watch(bikeModelsProvider).valueOrNull;
    String? bikeName;
    if (bikeModels != null && lead.interestedModelId != null) {
      for (final b in bikeModels) {
        if (b.id == lead.interestedModelId) {
          bikeName = b.displayName;
          break;
        }
      }
    }

    return DocSheet(
      spine: _spine,
      onTap: onTap,
      padding: const EdgeInsets.all(Ds.s3 + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lead.customerName,
                  style: text.titleMedium?.copyWith(color: Ds.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Ds.s2),
              if (lead.aiIntent != null)
                IntentBadge(intent: lead.aiIntent!, compact: true),
            ],
          ),
          const SizedBox(height: 5),
          // The mobile number in the figure register: it is a number to be read
          // off and dialled, not prose.
          Text(
            lead.mobile,
            style: Ds.figure(13, weight: 560, color: Ds.inkSoft),
          ),
          if (bikeName != null) ...[
            const SizedBox(height: Ds.s2),
            Row(
              children: [
                const Icon(Icons.two_wheeler_outlined,
                    size: 14, color: Ds.inkMuted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    bikeName,
                    style: text.bodySmall?.copyWith(color: Ds.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Ds.s3),
          // Wrap, so a long status and a date never overflow a narrow phone.
          Wrap(
            spacing: Ds.s2,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: lead.status, dense: true),
              if (lead.tentativePurchaseDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 12, color: Ds.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM').format(lead.tentativePurchaseDate!),
                      style: Ds.figure(11.5, weight: 560, color: Ds.inkMuted),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
