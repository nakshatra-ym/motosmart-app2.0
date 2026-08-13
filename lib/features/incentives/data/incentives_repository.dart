import '../../../models/employee_incentive.dart';

/// `GET /incentives?month=` (all employees at the current dealer),
/// `GET /incentives/employee/{id}`.
abstract class IncentivesRepository {
  Future<IncentiveSummary> getSummary({required DateTime month});

  Future<EmployeeIncentive> getForEmployee(String employeeId, {required DateTime month});
}
