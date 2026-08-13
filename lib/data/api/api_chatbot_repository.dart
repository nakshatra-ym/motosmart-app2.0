import '../../core/network/api_client.dart';
import '../../features/chatbot/data/chatbot_repository.dart';
import '../../models/chat_message.dart';
import '../../models/json_utils.dart';

/// `POST /chatbot/message`, `GET /chatbot/history`.
///
/// Server-side this is Bedrock-backed and persists both turns, so — unlike the
/// mock path — there is no client-side Groq call and no local transcript to
/// keep. Conversation continuity is implicit: omitting `conversation_id`
/// continues the customer's latest conversation.
class ApiChatbotRepository implements ChatbotRepository {
  const ApiChatbotRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ChatMessage>> history() async {
    final response = await _api.getObject('/chatbot/history', query: {'limit': 100});
    return asMapList(response['messages']).map(ChatMessage.fromJson).toList();
  }

  @override
  Future<ChatMessage> sendMessage(String text) async {
    final response = await _api.post('/chatbot/message', body: {'message': text});
    // Both turns come back; the user's is already on screen, so only the
    // assistant's reply is returned. The endpoint always yields a reply — it
    // falls back to canned text if Bedrock is unavailable.
    return ChatMessage.fromJson(asMap(response['assistant_message']));
  }
}
