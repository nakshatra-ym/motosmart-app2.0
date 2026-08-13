import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/ticket_ai_chips.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/enums.dart';
import '../../../models/service_request.dart';
import '../../public/data/public_providers.dart';
import '../data/tickets_providers.dart';

/// Dealer-side list of service tickets raised by their customers.
class TicketsListScreen extends ConsumerWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsListProvider);
    final store = ref.watch(mockDataStoreProvider);
    final bikeModels = ref.watch(publicModelsProvider).valueOrNull;
    final theme = Theme.of(context);

    String customerName(ServiceRequest ticket) {
      final fromApi = ticket.customerName;
      if (fromApi != null && fromApi.isNotEmpty) return fromApi;
      for (final c in store.customers) {
        if (c.id == ticket.customerId) return c.name;
      }
      return 'Unknown customer';
    }

    String? vehicleLabel(ServiceRequest ticket) {
      final fromApi = ticket.vehicleLabel;
      if (fromApi != null && fromApi.isNotEmpty) return fromApi;
      for (final v in store.vehicles) {
        if (v.id == ticket.vehicleId) {
          String? modelName;
          if (bikeModels != null) {
            for (final m in bikeModels) {
              if (m.id == v.bikeModelId) {
                modelName = m.displayName;
                break;
              }
            }
          }
          return '${modelName ?? 'Vehicle'} · ${v.registrationNo}';
        }
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tickets')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ticketsListProvider),
        child: AsyncValueWidget<List<ServiceRequest>>(
          value: ticketsAsync,
          onRetry: () => ref.invalidate(ticketsListProvider),
          data: (tickets) {
            if (tickets.isEmpty) {
              return const EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'No tickets yet',
                subtitle: 'Service requests raised by your customers will show up here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    onTap: () => context.push('/dealer/tickets/${ticket.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(ticket.type, style: theme.textTheme.titleMedium),
                              ),
                              _StatusChip(status: ticket.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            customerName(ticket),
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                          ),
                          if (vehicleLabel(ticket) != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              vehicleLabel(ticket)!,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                          if (ticket.aiPriority != null || ticket.aiCategory != null) ...[
                            const SizedBox(height: 10),
                            TicketAiChips(
                              priority: ticket.aiPriority,
                              category: ticket.aiCategory,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            ticket.aiSummary ?? ticket.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            DateFormat('d MMM yyyy, h:mm a').format(ticket.createdAt),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ServiceRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ServiceRequestStatus.open => AppColors.statusNew,
      ServiceRequestStatus.inProgress => AppColors.statusFollowUp,
      ServiceRequestStatus.resolved => AppColors.statusClosedWon,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
