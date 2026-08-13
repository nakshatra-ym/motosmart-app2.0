import 'enums.dart';
import 'json_utils.dart';

enum NotificationRecipientType { employee, customer }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientType,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final NotificationRecipientType recipientType;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        recipientType: recipientType,
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        payload: payload,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        recipientType: asString(json['recipient_type']) == 'CUSTOMER'
            ? NotificationRecipientType.customer
            : NotificationRecipientType.employee,
        recipientId: asString(json['recipient_id']),
        type: NotificationType.fromValue(asString(json['type'])),
        title: asString(json['title']),
        // `body` and `payload_json` are both nullable server-side.
        body: asString(json['body']),
        payload: asMap(json['payload_json']),
        isRead: json['is_read'] as bool? ?? false,
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipient_type': recipientType == NotificationRecipientType.customer
            ? 'CUSTOMER'
            : 'EMPLOYEE',
        'recipient_id': recipientId,
        'type': type.value,
        'title': title,
        'body': body,
        'payload_json': payload,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}
