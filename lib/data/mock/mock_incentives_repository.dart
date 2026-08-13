import '../../core/network/api_exception.dart';
import '../../features/incentives/data/incentives_repository.dart';
import '../../models/employee_incentive.dart';
import 'mock_data_store.dart';

/// Stands in for `incentive_rules` + `services/incentives.py: recompute()`
/// — simple flat rates per event, computed on the fly from leads/test-ride
/// data already in the mock store rather than a separate persisted table.
class MockIncentivesRepository implements IncentivesRepository {
  MockIncentivesRepository(this._store, {required String Function() currentDealerId})
      : _currentDealerId = currentDealerId;

  static const _conversionRate = 500.0;
  static const _testRideRate = 50.0;

  final MockDataStore _store;
  final String Function() _currentDealerId;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 300));

  bool _inMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  EmployeeIncentive _computeFor(String employeeId, DateTime month) {
    final employee = _store.employees.firstWhere((e) => e.id == employeeId);
    final myLeads = _store.leads.where((l) => l.assignedEmployeeId == employeeId);

    final leadsThisMonth = myLeads.where((l) => _inMonth(l.createdAt, month)).length;
    final conversionsThisMonth = myLeads
        .where((l) => l.convertedCustomerId != null && _inMonth(l.updatedAt, month))
        .length;
    final testRidesThisMonth = _store.testRideBookings.where((b) {
      if (!_inMonth(b.createdAt, month)) return false;
      final lead = _store.leads.where((l) => l.id == b.linkedLeadId);
      return lead.isNotEmpty && lead.first.assignedEmployeeId == employeeId;
    }).length;

    final total = conversionsThisMonth * _conversionRate + testRidesThisMonth * _testRideRate;

    return EmployeeIncentive(
      employeeId: employee.id,
      employeeName: employee.name,
      periodMonth: month,
      leadsCount: leadsThisMonth,
      conversionsCount: conversionsThisMonth,
      testRidesCount: testRidesThisMonth,
      totalIncentive: total,
    );
  }

  @override
  Future<IncentiveSummary> getSummary({required DateTime month}) async {
    await _simulateLatency();
    final dealerId = _currentDealerId();
    final employees = _store.employees.where((e) => e.dealerId == dealerId);
    final byEmployee = employees.map((e) => _computeFor(e.id, month)).toList()
      ..sort((a, b) => b.totalIncentive.compareTo(a.totalIncentive));
    return IncentiveSummary(periodMonth: month, byEmployee: byEmployee);
  }

  @override
  Future<EmployeeIncentive> getForEmployee(String employeeId, {required DateTime month}) async {
    await _simulateLatency();
    final exists = _store.employees.any((e) => e.id == employeeId);
    if (!exists) throw const ApiException('Employee not found.', statusCode: 404);
    return _computeFor(employeeId, month);
  }
}
