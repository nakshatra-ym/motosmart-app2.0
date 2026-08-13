import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/design.dart';
import '../../../core/widgets/document.dart';
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

    // The API sends the customer and vehicle on the ticket, because the dealer
    // app has no way to look them up itself. Only mock mode falls back to the
    // in-memory store — reading the store first is what produced
    // "Unknown customer" for every real ticket.
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SERVICE DESK', style: Ds.label()),
            Text('Job cards', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ticketsListProvider),
        child: AsyncValueWidget<List<ServiceRequest>>(
          value: ticketsAsync,
          onRetry: () => ref.invalidate(ticketsListProvider),
          data: (tickets) {
            if (tickets.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No job cards open',
                subtitle:
                    'Service requests your customers raise arrive here, sorted with the urgent ones first.',
              );
            }
            return ListView.separated(
              padding: Ds.pagePad(context),
              itemCount: tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: Ds.s3),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final text = Theme.of(context).textTheme;
                final urgent = ticket.aiPriority == TicketPriority.urgent;
                return DocPage(
                  child: DocSheet(
                    // The spine is the AI's priority, so the queue reads down
                    // its left edge before anybody reads a word.
                    spine: ticket.aiPriority == null
                        ? Ds.line
                        : TicketAiChips.colorFor(ticket.aiPriority!),
                    tint: urgent ? Ds.alert.withValues(alpha: 0.045) : null,
                    emphasis: urgent,
                    onTap: () => context.push('/dealer/tickets/${ticket.id}'),
                    padding: const EdgeInsets.all(Ds.s3 + 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                ticket.type,
                                style: text.titleMedium?.copyWith(color: Ds.ink),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: Ds.s2),
                            _StatusChip(status: ticket.status),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Who raised it, and on which bike — the dealer is
                        // answering a person, not a row.
                        Text(
                          customerName(ticket),
                          style: text.bodyMedium?.copyWith(color: Ds.inkSoft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (vehicleLabel(ticket) != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            vehicleLabel(ticket)!,
                            style: text.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (ticket.aiPriority != null || ticket.aiCategory != null) ...[
                          const SizedBox(height: Ds.s3),
                          TicketAiChips(
                            priority: ticket.aiPriority,
                            category: ticket.aiCategory,
                          ),
                        ],
                        const SizedBox(height: Ds.s3),
                        // The AI one-liner reads better in a queue than the
                        // customer's full prose; falls back to the prose.
                        Text(
                          ticket.aiSummary ?? ticket.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: Ds.inkSoft),
                        ),
                        const SizedBox(height: Ds.s3),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 11.5, color: Ds.inkMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                DateFormat('d MMM, h:mm a').format(ticket.createdAt),
                                style: Ds.figure(11, weight: 540, color: Ds.inkMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ticket.messageCount > 0) ...[
                              const Icon(Icons.forum_outlined,
                                  size: 11.5, color: Ds.inkMuted),
                              const SizedBox(width: 3),
                              Text(
                                '${ticket.messageCount}',
                                style: Ds.figure(11, weight: 620, color: Ds.inkMuted),
                              ),
                            ],
                          ],
                        ),
                      ],
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
      ServiceRequestStatus.open => Ds.info,
      ServiceRequestStatus.inProgress => Ds.caution,
      ServiceRequestStatus.resolved => Ds.positive,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Ds.s2, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Ds.rSm),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: Ds.label(color: color).copyWith(fontSize: 10),
      ),
    );
  }
}
