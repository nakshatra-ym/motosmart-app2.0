import '../../core/network/api_client.dart';
import '../../features/dashboard/data/dashboard_repository.dart';
import '../../models/dashboard_summary.dart';

/// `GET /dashboard/summary` — scoped to the caller's dealer by their token.
class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository(this._api);

  final ApiClient _api;

  @override
  Future<DashboardSummary> getSummary() async {
    return DashboardSummary.fromJson(await _api.getObject('/dashboard/summary'));
  }
}
