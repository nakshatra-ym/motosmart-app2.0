import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_incentives_repository.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/employee_incentive.dart';
import 'incentives_repository.dart';

final incentivesRepositoryProvider = Provider<IncentivesRepository>((ref) {
  return MockIncentivesRepository(
    ref.watch(mockDataStoreProvider),
    currentDealerId: () =>
        ref.read(authControllerProvider).valueOrNull?.employee?.dealerId ?? '',
  );
});

/// The month being viewed on the incentives screen; defaults to the
/// current month.
final incentivesMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final incentiveSummaryProvider = FutureProvider.autoDispose<IncentiveSummary>((ref) async {
  final month = ref.watch(incentivesMonthProvider);
  return ref.watch(incentivesRepositoryProvider).getSummary(month: month);
});
