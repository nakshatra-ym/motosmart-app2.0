import '../../core/network/api_exception.dart';
import '../../features/tickets/data/tickets_repository.dart';
import '../../models/enums.dart';
import '../../models/service_message.dart';
import '../../models/service_request.dart';
import 'mock_data_store.dart';

class MockTicketsRepository implements TicketsRepository {
  MockTicketsRepository(
    this._store, {
    required String Function() currentDealerId,
  }) : _currentDealerId = currentDealerId;

  final MockDataStore _store;
  final String Function() _currentDealerId;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<ServiceRequest>> listTickets() async {
    await _simulateLatency();
    final dealerId = _currentDealerId();
    final list = _store.serviceRequests.where((r) => r.dealerId == dealerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<ServiceRequest> getTicket(String id) async {
    await _simulateLatency();
    try {
      return _store.serviceRequests.firstWhere((r) => r.id == id);
    } catch (_) {
      throw const ApiException('Service request not found.', statusCode: 404);
    }
  }

  @override
  Future<ServiceRequest> updateStatus(String id, ServiceRequestStatus status) async {
    await _simulateLatency();
    final index = _store.serviceRequests.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw const ApiException('Service request not found.', statusCode: 404);
    }
    final updated = _store.serviceRequests[index].copyWith(status: status);
    _store.serviceRequests[index] = updated;
    return updated;
  }

  @override
  Future<List<ServiceMessage>> listMessages(String ticketId) async {
    await _simulateLatency();
    final list = _store.serviceMessages.where((m) => m.serviceRequestId == ticketId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<ServiceMessage> sendMessage(String ticketId, String message) async {
    await _simulateLatency();
    final dealerMessage = ServiceMessage(
      id: _store.newId('SVCMSG'),
      serviceRequestId: ticketId,
      senderType: MessageSenderType.dealer,
      senderId: _currentDealerId(),
      message: message,
      createdAt: DateTime.now(),
    );
    _store.serviceMessages.add(dealerMessage);
    return dealerMessage;
  }
}
