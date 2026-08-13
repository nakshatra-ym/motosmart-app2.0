import 'json_utils.dart';

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

  factory EmployeeIncentive.fromJson(Map<String, dynamic> json) => EmployeeIncentive(
        employeeId: asString(json['employee_id']),
        employeeName: asString(json['employee_name'], fallback: 'Unassigned'),
        periodMonth: parsePeriodMonth(json['period_month']),
        leadsCount: asInt(json['leads_count']),
        conversionsCount: asInt(json['conversions_count']),
        testRidesCount: asInt(json['test_rides_count']),
        totalIncentive: asDouble(json['total_incentive']),
      );
}

class IncentiveSummary {
  const IncentiveSummary({required this.periodMonth, required this.byEmployee});

  final DateTime periodMonth;
  final List<EmployeeIncentive> byEmployee;

  double get dealerTotal => byEmployee.fold(0, (sum, e) => sum + e.totalIncentive);

  factory IncentiveSummary.fromJson(Map<String, dynamic> json) => IncentiveSummary(
        periodMonth: parsePeriodMonth(json['period_month']),
        byEmployee:
            asMapList(json['employees']).map(EmployeeIncentive.fromJson).toList(),
      );
}

/// The API reports the period as `"YYYY-MM"`; the models carry a [DateTime]
/// pinned to the first of that month.
DateTime parsePeriodMonth(Object? value) {
  final raw = asString(value);
  final parts = raw.split('-');
  if (parts.length >= 2) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year != null && month != null) return DateTime(year, month);
  }
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}
