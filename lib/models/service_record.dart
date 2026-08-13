import 'json_utils.dart';

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceDate,
    required this.odometerKm,
    required this.serviceType,
    required this.cost,
    required this.nextServiceDate,
    required this.nextServiceKm,
  });

  final String id;
  final String vehicleId;
  final DateTime serviceDate;
  final int odometerKm;
  final String serviceType;
  final double cost;
  final DateTime? nextServiceDate;
  final int? nextServiceKm;

  factory ServiceRecord.fromJson(Map<String, dynamic> json) => ServiceRecord(
        id: asString(json['id']),
        vehicleId: asString(json['vehicle_id']),
        serviceDate: asDate(json['service_date']),
        odometerKm: asInt(json['odometer_km']),
        serviceType: asString(json['service_type'], fallback: 'Service'),
        // `cost` is a nullable Decimal — arrives as a JSON string when set.
        cost: asDouble(json['cost']),
        nextServiceDate: asDateOrNull(json['next_service_date']),
        nextServiceKm: asIntOrNull(json['next_service_km']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'service_date': serviceDate.toIso8601String(),
        'odometer_km': odometerKm,
        'service_type': serviceType,
        'cost': cost,
        'next_service_date': nextServiceDate?.toIso8601String(),
        'next_service_km': nextServiceKm,
      };
}
