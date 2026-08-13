import '../../../models/dashboard_summary.dart';

/// Mirrors `GET /dashboard/summary` — scoped to the current dealer-staff
/// user via their auth token, so it takes no id/filter arguments.
abstract class DashboardRepository {
  Future<DashboardSummary> getSummary();
}
