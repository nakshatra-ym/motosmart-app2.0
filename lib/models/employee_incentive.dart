/// One row of `GET /incentives?month=` — a single employee's rollup for
/// the period, mirroring the `employee_incentives` table.
class EmployeeIncentive {
  const EmployeeIncentive({
    required this.employeeId,
    required this.employeeName,
    required this.periodMonth,
    required this.leadsCount,
    required this.conversionsCount,
    required this.testRidesCount,
    required this.totalIncentive,
  });

  final String employeeId;
  final String employeeName;
  final DateTime periodMonth;
  final int leadsCount;
  final int conversionsCount;
  final int testRidesCount;
  final double totalIncentive;
}

class IncentiveSummary {
  const IncentiveSummary({required this.periodMonth, required this.byEmployee});

  final DateTime periodMonth;
  final List<EmployeeIncentive> byEmployee;

  double get dealerTotal => byEmployee.fold(0, (sum, e) => sum + e.totalIncentive);
}
