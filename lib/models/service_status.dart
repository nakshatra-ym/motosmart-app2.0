import 'json_utils.dart';
import 'service_record.dart';

/// `GET /vehicles/{id}/service-status` — last service done + next due, by
/// both time and km, with a due/overdue indicator.
class ServiceStatus {
  const ServiceStatus({
    required this.lastService,
    required this.nextServiceDate,
    required this.nextServiceKm,
    required this.currentOdometerKm,
    this.serverIsOverdue,
    this.message,
  });

  final ServiceRecord? lastService;
  final DateTime? nextServiceDate;
  final int? nextServiceKm;
  final int currentOdometerKm;

  /// The API's own verdict (`ServiceStatusOut.is_overdue`). Preferred over the
  /// local date/km comparison when present, since the server also accounts for
  /// vehicles that have never been serviced.
  final bool? serverIsOverdue;

  /// Human-readable status line from the API, when it supplied one.
  final String? message;

  bool get isOverdueByDate =>
      nextServiceDate != null && nextServiceDate!.isBefore(DateTime.now());

  bool get isOverdueByKm => nextServiceKm != null && currentOdometerKm >= nextServiceKm!;

  bool get isOverdue => serverIsOverdue ?? (isOverdueByDate || isOverdueByKm);

  /// Maps `ServiceStatusOut`, which reports the last service as flat
  /// `last_service_*` fields rather than a nested record. Those are rebuilt into
  /// a [ServiceRecord] (id left blank — it is not a fetchable row here) because
  /// that is what the UI already renders.
  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    final lastDate = asDateOrNull(json['last_service_date']);
    return ServiceStatus(
      lastService: lastDate == null
          ? null
          : ServiceRecord(
              id: '',
              vehicleId: asString(json['vehicle_id']),
              serviceDate: lastDate,
              odometerKm: asInt(json['last_service_km']),
              serviceType: asString(json['last_service_type'], fallback: 'Service'),
              cost: 0,
              nextServiceDate: asDateOrNull(json['next_service_date']),
              nextServiceKm: asIntOrNull(json['next_service_km']),
            ),
      nextServiceDate: asDateOrNull(json['next_service_date']),
      nextServiceKm: asIntOrNull(json['next_service_km']),
      currentOdometerKm: asInt(json['odometer_km']),
      serverIsOverdue: json['is_overdue'] as bool?,
      message: json['message'] as String?,
    );
  }
}
