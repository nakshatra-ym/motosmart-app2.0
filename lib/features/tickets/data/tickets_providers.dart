import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/api/api_tickets_repository.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../data/mock/mock_tickets_repository.dart';
import '../../incentives/data/incentives_providers.dart';
import '../../../models/enums.dart';
import '../../../models/service_message.dart';
import '../../../models/service_request.dart';
import 'tickets_repository.dart';

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockTicketsRepository(
      ref.watch(mockDataStoreProvider),
      currentDealerId: () =>
          ref.read(authControllerProvider).valueOrNull?.employee?.dealerId ?? '',
    );
  }
  return ApiTicketsRepository(ref.watch(apiClientProvider));
});

/// The tickets screen's two-way split: resolved tickets move out of the
/// working queue entirely once closed, rather than sitting in the same list.
enum TicketView { active, archived }

final ticketViewProvider = StateProvider<TicketView>((ref) => TicketView.active);

final ticketsListProvider = FutureProvider.autoDispose<List<ServiceRequest>>((ref) async {
  final view = ref.watch(ticketViewProvider);
  final tickets = await ref.watch(ticketsRepositoryProvider).listTickets();

  if (view == TicketView.archived) {
    final archived = tickets.where((t) => t.status == ServiceRequestStatus.resolved).toList();
    return archived
      ..sort((a, b) => (b.resolvedAt ?? b.createdAt).compareTo(a.resolvedAt ?? a.createdAt));
  }

  final active = tickets.where((t) => t.status != ServiceRequestStatus.resolved).toList();

  // In-progress tickets surface before untouched open ones; AI priority
  // (newest first within a priority) breaks ties inside each status group.
  // Untriaged tickets sort as if Normal so they never sink below routine work.
  int statusRank(ServiceRequest t) => t.status == ServiceRequestStatus.inProgress ? 0 : 1;
  int priorityRank(ServiceRequest t) => (t.aiPriority ?? TicketPriority.normal).rank;

  return active
    ..sort((a, b) {
      final byStatus = statusRank(a).compareTo(statusRank(b));
      if (byStatus != 0) return byStatus;
      final byPriority = priorityRank(a).compareTo(priorityRank(b));
      return byPriority != 0 ? byPriority : b.createdAt.compareTo(a.createdAt);
    });
});

final ticketDetailProvider =
    FutureProvider.autoDispose.family<ServiceRequest, String>((ref, id) async {
  return ref.watch(ticketsRepositoryProvider).getTicket(id);
});

final ticketMessagesProvider =
    FutureProvider.autoDispose.family<List<ServiceMessage>, String>((ref, ticketId) async {
  return ref.watch(ticketsRepositoryProvider).listMessages(ticketId);
});

/// Call after any mutation (status change, new message) so the list, detail,
/// and thread all reflect it immediately.
void invalidateTicketsData(WidgetRef ref, {String? ticketId}) {
  ref.invalidate(ticketsListProvider);
  // Resolving a ticket earns its closer an incentive, so the rollup is stale the
  // moment a status changes. Every ticket mutation routes through here, which is
  // why the invalidation lives here rather than at each call site.
  ref.invalidate(incentiveSummaryProvider);
  if (ticketId != null) {
    ref.invalidate(ticketDetailProvider(ticketId));
    ref.invalidate(ticketMessagesProvider(ticketId));
  }
}
