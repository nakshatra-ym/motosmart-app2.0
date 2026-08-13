import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/api/api_chatbot_repository.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/env.dart';
import '../../../data/mock/mock_chatbot_repository.dart';
import '../../../data/mock/mock_chatbot_service.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/chat_message.dart';
import 'chatbot_repository.dart';
import 'groq_chatbot_service.dart';

final chatbotServiceProvider = Provider<MockChatbotService>((ref) => MockChatbotService());

final groqChatbotServiceProvider = Provider<GroqChatbotService>((ref) {
  return GroqChatbotService(apiKey: Env.groqApiKey, model: Env.groqModel);
});

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockChatbotRepository(
      ref.watch(mockDataStoreProvider),
      ref.watch(chatbotServiceProvider),
      currentCustomerId: () => ref.read(authControllerProvider).valueOrNull?.customer?.id,
      groqChatbot: ref.watch(groqChatbotServiceProvider),
    );
  }
  return ApiChatbotRepository(ref.watch(apiClientProvider));
});

final chatHistoryProvider = FutureProvider.autoDispose<List<ChatMessage>>((ref) async {
  return ref.watch(chatbotRepositoryProvider).history();
});
