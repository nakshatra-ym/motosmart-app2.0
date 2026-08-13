import 'enums.dart';
import 'json_utils.dart';

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
    this.aiCategory,
    this.aiPriority,
    this.aiSummary,
    this.customerName,
    this.customerPhone,
    this.vehicleLabel,
    this.messageCount = 0,
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

  /// AI triage assigned when the ticket was raised. Null if classification
  /// could not run - the ticket is still valid, it just shows no chips.
  final TicketCategory? aiCategory;
  final TicketPriority? aiPriority;
  final String? aiSummary;

  /// Who raised it and on what, denormalised by the API. The dealer queue cannot
  /// look these up itself (it has no access to the customers table), which is why
  /// they arrive on the ticket.
  final String? customerName;
  final String? customerPhone;
  final String? vehicleLabel;

  /// How many messages the thread holds. Sent by the API so a queue can show
  /// which conversations are already running without opening each one.
  final int messageCount;

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
        aiCategory: aiCategory,
        aiPriority: aiPriority,
        aiSummary: aiSummary,
        customerName: customerName,
        customerPhone: customerPhone,
        vehicleLabel: vehicleLabel,
        messageCount: messageCount,
      );

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
        id: json['id'] as String,
        vehicleId: asString(json['vehicle_id']),
        customerId: asString(json['customer_id']),
        // dealer_id, type, and description are all nullable server-side.
        dealerId: asString(json['dealer_id']),
        type: asString(json['type'], fallback: 'General'),
        description: asString(json['description']),
        status: ServiceRequestStatus.fromValue(asString(json['status'])),
        preferredDate: asDateOrNull(json['preferred_date']),
        createdAt: asDate(json['created_at']),
        aiCategory: TicketCategory.tryFromValue(json['ai_category'] as String?),
        aiPriority: TicketPriority.tryFromValue(json['ai_priority'] as String?),
        aiSummary: json['ai_summary'] as String?,
        customerName: json['customer_name'] as String?,
        customerPhone: json['customer_phone'] as String?,
        vehicleLabel: json['vehicle_label'] as String?,
        messageCount: asInt(json['message_count']),
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
        'ai_category': aiCategory?.value,
        'ai_priority': aiPriority?.value,
        'ai_summary': aiSummary,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'vehicle_label': vehicleLabel,
        'message_count': messageCount,
      };
}
