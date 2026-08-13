import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/api/api_incentives_repository.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_incentives_repository.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/employee_incentive.dart';
import 'incentives_repository.dart';

final incentivesRepositoryProvider = Provider<IncentivesRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockIncentivesRepository(
      ref.watch(mockDataStoreProvider),
      currentDealerId: () =>
          ref.read(authControllerProvider).valueOrNull?.employee?.dealerId ?? '',
    );
  }
  return ApiIncentivesRepository(ref.watch(apiClientProvider));
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

/// The signed-in employee's own row, which is all the incentives screen shows —
/// earnings are personal, and the API returns the whole roster only because it
/// is one query.
///
/// Null while the summary loads. An employee with no activity yet is still in
/// the response at zero, so a null row after loading means no matching employee,
/// not "nothing earned" — the screen renders zero either way.
final myIncentiveProvider = Provider.autoDispose<AsyncValue<EmployeeIncentive?>>((ref) {
  final employeeId = ref.watch(authControllerProvider).valueOrNull?.employee?.id;
  return ref.watch(incentiveSummaryProvider).whenData((summary) {
    for (final row in summary.byEmployee) {
      if (row.employeeId == employeeId) return row;
    }
    return null;
  });
});
