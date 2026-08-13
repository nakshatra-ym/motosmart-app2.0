import '../../../models/chat_message.dart';

/// `POST /chatbot/message` (-> Groq LLM, persists both turns), `GET /chatbot/history`.
abstract class ChatbotRepository {
  Future<List<ChatMessage>> history();

  /// Persists the user's message, generates an assistant reply, persists
  /// and returns that reply.
  Future<ChatMessage> sendMessage(String text);
}
