import 'enums.dart';

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
        serviceRequestId: json['service_request_id'] as String,
        senderType: MessageSenderType.fromValue(json['sender_type'] as String),
        senderId: json['sender_id'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
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
