import '../../core/network/api_exception.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../models/dashboard_summary.dart';
import 'mock_data_store.dart';

class MockDashboardRepository implements DashboardRepository {
  MockDashboardRepository(this._store, {required String? Function() currentEmployeeId})
      : _currentEmployeeId = currentEmployeeId;

  final MockDataStore _store;
  final String? Function() _currentEmployeeId;

  @override
  Future<DashboardSummary> getSummary() async {
    await Future.delayed(const Duration(milliseconds: 350));
    final employeeId = _currentEmployeeId();
    if (employeeId == null) {
      throw const ApiException('Not signed in.', statusCode: 401);
    }
    return _store.dashboardSummaryFor(employeeId);
  }
}
