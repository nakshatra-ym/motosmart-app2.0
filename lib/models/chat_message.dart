import 'enums.dart';
import 'json_utils.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: asString(json['id']),
        role: ChatRole.fromValue(asString(json['role'])),
        content: asString(json['content']),
        createdAt: asDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.value,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
