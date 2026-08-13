import 'enums.dart';
import 'json_utils.dart';

class ServiceMessage {
  const ServiceMessage({
    required this.id,
    required this.serviceRequestId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String serviceRequestId;
  final MessageSenderType senderType;
  final String senderId;
  final String message;
  final DateTime createdAt;

  factory ServiceMessage.fromJson(Map<String, dynamic> json) => ServiceMessage(
        id: json['id'] as String,
        serviceRequestId: asString(json['service_request_id']),
        senderType: MessageSenderType.fromValue(asString(json['sender_type'])),
        // Nullable server-side (a system-generated turn has no sender row).
        senderId: asString(json['sender_id']),
        message: asString(json['message']),
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_request_id': serviceRequestId,
        'sender_type': senderType.value,
        'sender_id': senderId,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}
