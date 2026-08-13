import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lead.aiIntent != null) IntentBadge(intent: lead.aiIntent!, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lead.mobile,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              if (bikeName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.two_wheeler, size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Text(bikeName, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  StatusChip(status: lead.status),
                  const Spacer(),
                  if (lead.tentativePurchaseDate != null)
                    Text(
                      DateFormat('d MMM').format(lead.tentativePurchaseDate!),
                      style: const TextStyle(fontSize: 12, color: Colors.black45),
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
