import '../../features/chatbot/data/chatbot_repository.dart';
import '../../features/chatbot/data/groq_chatbot_service.dart';
import '../../models/chat_message.dart';
import '../../models/enums.dart';
import '../../models/service_status.dart';
import 'mock_chatbot_service.dart';
import 'mock_data_store.dart';

class MockChatbotRepository implements ChatbotRepository {
  MockChatbotRepository(
    this._store,
    this._chatbot, {
    required String? Function() currentCustomerId,
    GroqChatbotService? groqChatbot,
  })  : _currentCustomerId = currentCustomerId,
        _groqChatbot = groqChatbot;

  final MockDataStore _store;
  final MockChatbotService _chatbot;
  final GroqChatbotService? _groqChatbot;
  final String? Function() _currentCustomerId;

  List<ChatMessage> _historyFor(String customerId) =>
      _store.chatHistoryByCustomer.putIfAbsent(customerId, () => []);

  ServiceStatus? _primaryVehicleServiceStatus(String customerId) {
    final vehicles = _store.vehiclesForCustomer(customerId);
    if (vehicles.isEmpty) return null;
    final vehicle = vehicles.first;
    final records = _store.serviceRecords.where((r) => r.vehicleId == vehicle.id).toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    final last = records.isEmpty ? null : records.first;
    return ServiceStatus(
      lastService: last,
      nextServiceDate: last?.nextServiceDate,
      nextServiceKm: last?.nextServiceKm,
      currentOdometerKm: vehicle.odometerKm,
    );
  }

  @override
  Future<List<ChatMessage>> history() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final customerId = _currentCustomerId();
    if (customerId == null) return const [];
    return List.unmodifiable(_historyFor(customerId));
  }

  @override
  Future<ChatMessage> sendMessage(String text) async {
    final customerId = _currentCustomerId();
    if (customerId == null) {
      throw StateError('Not signed in.');
    }
    final history = _historyFor(customerId);
    final priorHistory = List<ChatMessage>.unmodifiable(history);
    final now = DateTime.now();

    history.add(ChatMessage(
      id: _store.newId('CHATMSG'),
      role: ChatRole.user,
      content: text,
      createdAt: now,
    ));

    final serviceStatus = _primaryVehicleServiceStatus(customerId);
    final replyText = await _groqChatbot?.reply(priorHistory, text, serviceStatus: serviceStatus) ??
        _chatbot.reply(text, serviceStatus: serviceStatus);
    final replyMessage = ChatMessage(
      id: _store.newId('CHATMSG'),
      role: ChatRole.assistant,
      content: replyText,
      createdAt: DateTime.now(),
    );
    history.add(replyMessage);

    return replyMessage;
  }
}
