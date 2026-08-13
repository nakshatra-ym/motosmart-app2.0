import '../../core/network/api_client.dart';
import '../../features/incentives/data/incentives_repository.dart';
import '../../models/employee_incentive.dart';

/// `GET /incentives?month=`, `GET /incentives/employee/{id}`.
class ApiIncentivesRepository implements IncentivesRepository {
  const ApiIncentivesRepository(this._api);

  final ApiClient _api;

  @override
  Future<IncentiveSummary> getSummary({required DateTime month}) async {
    final response =
        await _api.getObject('/incentives', query: {'month': _month(month)});
    return IncentiveSummary.fromJson(response);
  }

  @override
  Future<EmployeeIncentive> getForEmployee(
    String employeeId, {
    required DateTime month,
  }) async {
    final response = await _api.getObject(
      '/incentives/employee/$employeeId',
      query: {'month': _month(month)},
    );
    return EmployeeIncentive.fromJson(response);
  }

  /// The API's `month` filter is validated against `^\d{4}-\d{2}$`.
  String _month(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
}
