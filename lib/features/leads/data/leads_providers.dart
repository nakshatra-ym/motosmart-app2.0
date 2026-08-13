import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/ai_classify_service.dart';
import '../../../data/mock/mock_leads_repository.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/bike_model.dart';
import '../../../models/enums.dart';
import '../../../models/lead.dart';
import '../../../models/lead_followup.dart';
import 'leads_repository.dart';

final aiClassifyServiceProvider = Provider<AiClassifyService>((ref) => AiClassifyService());

/// Swap for a dio-backed implementation once the real API is live —
/// nothing under features/leads/presentation depends on the mock directly.
final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return MockLeadsRepository(
    ref.watch(mockDataStoreProvider),
    ref.watch(aiClassifyServiceProvider),
    currentEmployeeId: () => ref.read(authControllerProvider).valueOrNull?.employee?.id ?? '',
    currentDealerId: () =>
        ref.read(authControllerProvider).valueOrNull?.employee?.dealerId ?? '',
  );
});

/// The leads list screen's status tabs — "Closed" conflates CLOSED_WON and
/// CLOSED_LOST (the backend only filters on a single status, so that split
/// is done client-side here rather than in the repository).
enum LeadTab { all, newLead, followUp, closed }

/// The Leads screen's top-level segment — test rides are just another kind
/// of lead activity, so they live as a second segment here rather than a
/// separate bottom-nav tab.
enum LeadsSegment { leads, testRides }

/// UI-only filter state for the leads list screen's search bar + status tabs.
final leadSearchQueryProvider = StateProvider<String>((ref) => '');
final leadTabProvider = StateProvider<LeadTab>((ref) => LeadTab.all);
final leadsSegmentProvider = StateProvider<LeadsSegment>((ref) => LeadsSegment.leads);

final leadsListProvider = FutureProvider.autoDispose<List<Lead>>((ref) async {
  final tab = ref.watch(leadTabProvider);
  final query = ref.watch(leadSearchQueryProvider);
  final all =
      await ref.watch(leadsRepositoryProvider).listLeads(query: query.isEmpty ? null : query);
  return switch (tab) {
    LeadTab.all => all,
    LeadTab.newLead => all.where((l) => l.status == LeadStatus.newLead).toList(),
    LeadTab.followUp => all.where((l) => l.status == LeadStatus.followUp).toList(),
    LeadTab.closed => all
        .where((l) => l.status == LeadStatus.closedWon || l.status == LeadStatus.closedLost)
        .toList(),
  };
});

final leadDetailProvider = FutureProvider.autoDispose.family<Lead, String>((ref, id) async {
  return ref.watch(leadsRepositoryProvider).getLead(id);
});

final leadFollowupsProvider =
    FutureProvider.autoDispose.family<List<LeadFollowup>, String>((ref, leadId) async {
  return ref.watch(leadsRepositoryProvider).listFollowups(leadId);
});

final bikeModelsProvider = FutureProvider<List<BikeModel>>((ref) async {
  return ref.watch(leadsRepositoryProvider).listBikeModels();
});

/// Call after any mutation (create/update lead, follow-up, classify,
/// convert) so the list, detail, and dashboard all reflect it immediately.
/// Takes [WidgetRef] since every call site is a screen/dialog callback.
void invalidateLeadsData(WidgetRef ref, {String? leadId}) {
  ref.invalidate(leadsListProvider);
  if (leadId != null) {
    ref.invalidate(leadDetailProvider(leadId));
    ref.invalidate(leadFollowupsProvider(leadId));
  }
}
