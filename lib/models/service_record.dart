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
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        odometerKm: json['odometer_km'] as int,
        serviceType: json['service_type'] as String,
        cost: (json['cost'] as num).toDouble(),
        nextServiceDate: json['next_service_date'] == null
            ? null
            : DateTime.parse(json['next_service_date'] as String),
        nextServiceKm: json['next_service_km'] as int?,
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
