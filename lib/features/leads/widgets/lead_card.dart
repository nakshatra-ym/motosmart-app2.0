import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/intent_badge.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/lead.dart';
import '../data/leads_providers.dart';

class LeadCard extends ConsumerWidget {
  const LeadCard({super.key, required this.lead, required this.onTap});

  final Lead lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.customerName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lead.aiIntent != null) IntentBadge(intent: lead.aiIntent!, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lead.mobile,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                      fontSize: 13,
                    ),
              ),
              if (bikeName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.two_wheeler, size: 14, color: AppColors.inkFaint),
                    const SizedBox(width: 6),
                    Text(
                      bikeName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusChip(status: lead.status),
                  const Spacer(),
                  if (lead.tentativePurchaseDate != null)
                    Text(
                      DateFormat('d MMM').format(lead.tentativePurchaseDate!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
