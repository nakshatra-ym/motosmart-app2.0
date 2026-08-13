import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_dashboard_repository.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/dashboard_summary.dart';
import 'dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return MockDashboardRepository(
    ref.watch(mockDataStoreProvider),
    currentEmployeeId: () => ref.read(authControllerProvider).valueOrNull?.employee?.id,
  );
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});
