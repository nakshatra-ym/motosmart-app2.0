import 'enums.dart';

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.vehicleId,
    required this.customerId,
    required this.dealerId,
    required this.type,
    required this.description,
    required this.status,
    required this.preferredDate,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String customerId;
  final String dealerId;
  final String type;
  final String description;
  final ServiceRequestStatus status;
  final DateTime? preferredDate;
  final DateTime createdAt;

  ServiceRequest copyWith({ServiceRequestStatus? status}) => ServiceRequest(
        id: id,
        vehicleId: vehicleId,
        customerId: customerId,
        dealerId: dealerId,
        type: type,
        description: description,
        status: status ?? this.status,
        preferredDate: preferredDate,
        createdAt: createdAt,
      );

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
        id: json['id'] as String,
        vehicleId: json['vehicle_id'] as String,
        customerId: json['customer_id'] as String,
        dealerId: json['dealer_id'] as String,
        type: json['type'] as String,
        description: json['description'] as String,
        status: ServiceRequestStatus.fromValue(json['status'] as String),
        preferredDate: json['preferred_date'] == null
            ? null
            : DateTime.parse(json['preferred_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicle_id': vehicleId,
        'customer_id': customerId,
        'dealer_id': dealerId,
        'type': type,
        'description': description,
        'status': status.value,
        'preferred_date': preferredDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
