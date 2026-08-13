import 'service_record.dart';

/// `GET /vehicles/{id}/service-status` — last service done + next due, by
/// both time and km, with a due/overdue indicator.
class ServiceStatus {
  const ServiceStatus({
    required this.lastService,
    required this.nextServiceDate,
    required this.nextServiceKm,
    required this.currentOdometerKm,
  });

  final ServiceRecord? lastService;
  final DateTime? nextServiceDate;
  final int? nextServiceKm;
  final int currentOdometerKm;

  bool get isOverdueByDate =>
      nextServiceDate != null && nextServiceDate!.isBefore(DateTime.now());

  bool get isOverdueByKm => nextServiceKm != null && currentOdometerKm >= nextServiceKm!;

  bool get isOverdue => isOverdueByDate || isOverdueByKm;
}
