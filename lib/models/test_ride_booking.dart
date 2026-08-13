import 'enums.dart';
import 'json_utils.dart';

class TestRideBooking {
  const TestRideBooking({
    required this.id,
    required this.bikeModelId,
    required this.name,
    required this.mobile,
    required this.preferredDate,
    required this.preferredTime,
    required this.dealerId,
    required this.status,
    required this.linkedLeadId,
    required this.createdAt,
  });

  final String id;
  final String bikeModelId;
  final String name;
  final String mobile;
  final DateTime preferredDate;
  final String preferredTime;
  final String dealerId;
  final TestRideStatus status;
  final String? linkedLeadId;
  final DateTime createdAt;

  TestRideBooking copyWith({TestRideStatus? status}) => TestRideBooking(
        id: id,
        bikeModelId: bikeModelId,
        name: name,
        mobile: mobile,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        dealerId: dealerId,
        status: status ?? this.status,
        linkedLeadId: linkedLeadId,
        createdAt: createdAt,
      );

  factory TestRideBooking.fromJson(Map<String, dynamic> json) => TestRideBooking(
        id: json['id'] as String,
        // bike_model_id, preferred_time, and created_at are all nullable
        // server-side (a booking need not name a model or a time).
        bikeModelId: asString(json['bike_model_id']),
        name: asString(json['name']),
        mobile: asString(json['mobile']),
        preferredDate: asDate(json['preferred_date']),
        preferredTime: asString(json['preferred_time']),
        dealerId: asString(json['dealer_id']),
        status: TestRideStatus.fromValue(asString(json['status'])),
        linkedLeadId: json['linked_lead_id'] as String?,
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bike_model_id': bikeModelId,
        'name': name,
        'mobile': mobile,
        'preferred_date': preferredDate.toIso8601String(),
        'preferred_time': preferredTime,
        'dealer_id': dealerId,
        'status': status.value,
        'linked_lead_id': linkedLeadId,
        'created_at': createdAt.toIso8601String(),
      };
}
