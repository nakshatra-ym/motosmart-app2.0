import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/chat_message.dart';
import '../../../models/enums.dart';
import '../../../models/service_status.dart';
import 'chat_guardrails.dart';

/// Calls Groq's OpenAI-compatible chat completions API, prompted as a
/// dedicated car & motorcycle assistant ("RideMate"). Returns null on any
/// failure — no key, network error, non-200, empty content — so the caller
/// can fall back to the offline rule-based reply instead of breaking the
/// chat mid-demo.
class GroqChatbotService {
  GroqChatbotService({required this.apiKey, required this.model});

  final String apiKey;
  final String model;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// [history] is prior turns for continuity; [latestUserText] is the new
  /// message to answer. [serviceStatus] (when known) is folded into the
  /// system prompt so the assistant can speak to the rider's own vehicle.
  Future<String?> reply(
    List<ChatMessage> history,
    String latestUserText, {
    ServiceStatus? serviceStatus,
  }) async {
    if (apiKey.isEmpty) return null;
    // Guardrail: obvious off-topic/jailbreak phrasing never reaches the API.
    if (ChatGuardrails.isObviouslyOffTopic(latestUserText)) {
      return ChatGuardrails.refusalMessage;
    }

    var systemPrompt = ChatGuardrails.systemPrompt;
    if (serviceStatus != null) {
      final due = serviceStatus.isOverdue
          ? 'overdue for service'
          : serviceStatus.nextServiceDate != null
              ? 'next due around ${serviceStatus.nextServiceDate!.day}/'
                  '${serviceStatus.nextServiceDate!.month}/${serviceStatus.nextServiceDate!.year}'
                  '${serviceStatus.nextServiceKm != null ? ' or at ${serviceStatus.nextServiceKm} km' : ''}'
              : 'not yet on a known service schedule';
      systemPrompt = '$systemPrompt\nContext: this rider\'s bike is $due.';
    }

    const historyLimit = 10;
    final recentHistory =
        history.length > historyLimit ? history.sublist(history.length - historyLimit) : history;

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      for (final m in recentHistory)
        {'role': m.role == ChatRole.user ? 'user' : 'assistant', 'content': m.content},
      {'role': 'user', 'content': latestUserText},
    ];

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      final text = (choices?.first as Map?)?['message']?['content'] as String?;

      return (text == null || text.trim().isEmpty) ? null : text.trim();
    } catch (_) {
      return null;
    }
  }
}
