import 'enums.dart';

class Lead {
  const Lead({
    required this.id,
    required this.dealerId,
    required this.assignedEmployeeId,
    required this.customerName,
    required this.mobile,
    required this.source,
    required this.interestedModelId,
    required this.currentBike,
    required this.tentativePurchaseDate,
    required this.status,
    required this.aiIntent,
    required this.notes,
    required this.convertedCustomerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String dealerId;
  final String? assignedEmployeeId;
  final String customerName;
  final String mobile;
  final LeadSource source;
  final String? interestedModelId;
  final String? currentBike;
  final DateTime? tentativePurchaseDate;
  final LeadStatus status;
  final AiIntent? aiIntent;
  final String? notes;
  final String? convertedCustomerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lead copyWith({
    String? assignedEmployeeId,
    String? interestedModelId,
    String? currentBike,
    DateTime? tentativePurchaseDate,
    LeadStatus? status,
    Object? aiIntent = _sentinel,
    String? notes,
    String? convertedCustomerId,
    DateTime? updatedAt,
  }) {
    return Lead(
      id: id,
      dealerId: dealerId,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      customerName: customerName,
      mobile: mobile,
      source: source,
      interestedModelId: interestedModelId ?? this.interestedModelId,
      currentBike: currentBike ?? this.currentBike,
      tentativePurchaseDate: tentativePurchaseDate ?? this.tentativePurchaseDate,
      status: status ?? this.status,
      aiIntent: identical(aiIntent, _sentinel) ? this.aiIntent : aiIntent as AiIntent?,
      notes: notes ?? this.notes,
      convertedCustomerId: convertedCustomerId ?? this.convertedCustomerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        dealerId: json['dealer_id'] as String,
        assignedEmployeeId: json['assigned_employee_id'] as String?,
        customerName: json['customer_name'] as String,
        mobile: json['mobile'] as String,
        source: LeadSource.fromValue(json['source'] as String),
        interestedModelId: json['interested_model_id'] as String?,
        currentBike: json['current_bike'] as String?,
        tentativePurchaseDate: json['tentative_purchase_date'] == null
            ? null
            : DateTime.parse(json['tentative_purchase_date'] as String),
        status: LeadStatus.fromValue(json['status'] as String),
        aiIntent: AiIntent.tryFromValue(json['ai_intent'] as String?),
        notes: json['notes'] as String?,
        convertedCustomerId: json['converted_customer_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dealer_id': dealerId,
        'assigned_employee_id': assignedEmployeeId,
        'customer_name': customerName,
        'mobile': mobile,
        'source': source.value,
        'interested_model_id': interestedModelId,
        'current_bike': currentBike,
        'tentative_purchase_date': tentativePurchaseDate?.toIso8601String(),
        'status': status.value,
        'ai_intent': aiIntent?.value,
        'notes': notes,
        'converted_customer_id': convertedCustomerId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

const _sentinel = Object();
