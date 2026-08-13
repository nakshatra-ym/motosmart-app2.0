import '../../features/chatbot/data/chat_guardrails.dart';
import '../../models/service_status.dart';

/// Offline fallback for when the Groq-backed [GroqChatbotService] is
/// unavailable (no API key, network error, non-200 response). Keyword-driven,
/// deterministic, and offline — same "stub-friendly, never breaks the demo"
/// philosophy as [AiClassifyService].
class MockChatbotService {
  String reply(String userText, {ServiceStatus? serviceStatus}) {
    if (ChatGuardrails.isObviouslyOffTopic(userText)) {
      return ChatGuardrails.refusalMessage;
    }

    final text = userText.toLowerCase();

    if (text.contains('service') && (text.contains('due') || text.contains('next'))) {
      if (serviceStatus == null) {
        return "I don't see a vehicle on your account yet, so I can't check a service date. "
            'Add a vehicle or contact your dealer to get one linked.';
      }
      if (serviceStatus.isOverdue) {
        return 'Your bike looks overdue for service — please book a slot soon to avoid '
            'further wear. You can raise a service request from the Service tab.';
      }
      final date = serviceStatus.nextServiceDate;
      final km = serviceStatus.nextServiceKm;
      return 'Your next service is due ${date != null ? 'around ${date.day}/${date.month}/${date.year}' : 'soon'}'
          '${km != null ? ' or at $km km' : ''}, whichever comes first.';
    }
    if (text.contains('book') && text.contains('test')) {
      return 'You can book a test ride from the public catalog\'s "Book test ride" button — '
          'no login needed for that part.';
    }
    if (text.contains('price') || text.contains('cost') || text.contains('emi')) {
      return "Pricing varies by model and variant — check the bike's detail page for the "
          'on-road price, or ask your dealer for the latest EMI options.';
    }
    if (text.contains('hello') || text.contains('hi') || text.contains('hey')) {
      return "Hi! I'm your Yamaha assistant. Ask me about your service due date, "
          'test rides, or raising a service request.';
    }
    if (text.contains('thank')) {
      return "You're welcome! Anything else I can help with?";
    }
    return "I can help with service due dates, test-ride bookings, and general pricing "
        "questions. Could you rephrase, or raise a service request if it's about your bike?";
  }
}
