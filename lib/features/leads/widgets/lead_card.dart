import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';
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
    final theme = Theme.of(context);
    String? bikeName;
    if (bikeModels != null && lead.interestedModelId != null) {
      for (final b in bikeModels) {
        if (b.id == lead.interestedModelId) {
          bikeName = b.displayName;
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lead.aiIntent != null) IntentBadge(intent: lead.aiIntent!, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lead.mobile,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (bikeName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const AppIconWell(
                      icon: Icons.two_wheeler_rounded,
                      size: 28,
                      iconSize: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bikeName,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
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
                      style: theme.textTheme.labelSmall,
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
