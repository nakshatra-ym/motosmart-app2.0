import '../../core/network/api_exception.dart';
import '../../features/service/data/service_repository.dart';
import '../../models/enums.dart';
import '../../models/service_message.dart';
import '../../models/service_request.dart';
import 'mock_data_store.dart';

class MockServiceRepository implements ServiceRepository {
  MockServiceRepository(
    this._store, {
    required String? Function() currentCustomerId,
    required String Function() currentDealerId,
  })  : _currentCustomerId = currentCustomerId,
        _currentDealerId = currentDealerId;

  final MockDataStore _store;
  final String? Function() _currentCustomerId;
  final String Function() _currentDealerId;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<ServiceRequest>> listRequests() async {
    await _simulateLatency();
    final customerId = _currentCustomerId();
    if (customerId == null) return const [];
    final list =
        _store.serviceRequests.where((r) => r.customerId == customerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<ServiceRequest> getRequest(String id) async {
    await _simulateLatency();
    try {
      return _store.serviceRequests.firstWhere((r) => r.id == id);
    } catch (_) {
      throw const ApiException('Service request not found.', statusCode: 404);
    }
  }

  @override
  Future<ServiceRequest> createRequest({
    required String vehicleId,
    required String type,
    required String description,
    DateTime? preferredDate,
  }) async {
    await _simulateLatency();
    final customerId = _currentCustomerId();
    if (customerId == null) {
      throw const ApiException('Not signed in.', statusCode: 401);
    }
    final request = ServiceRequest(
      id: _store.newId('SVCREQ'),
      vehicleId: vehicleId,
      customerId: customerId,
      dealerId: _currentDealerId(),
      type: type,
      description: description,
      status: ServiceRequestStatus.open,
      preferredDate: preferredDate,
      createdAt: DateTime.now(),
    );
    _store.serviceRequests.add(request);

    _store.serviceMessages.add(ServiceMessage(
      id: _store.newId('SVCMSG'),
      serviceRequestId: request.id,
      senderType: MessageSenderType.customer,
      senderId: customerId,
      message: description,
      createdAt: DateTime.now(),
    ));

    return request;
  }

  @override
  Future<List<ServiceMessage>> listMessages(String requestId) async {
    await _simulateLatency();
    final list = _store.serviceMessages.where((m) => m.serviceRequestId == requestId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  @override
  Future<ServiceMessage> sendMessage(String requestId, String message) async {
    await _simulateLatency();
    final customerId = _currentCustomerId();
    if (customerId == null) {
      throw const ApiException('Not signed in.', statusCode: 401);
    }
    final customerMessage = ServiceMessage(
      id: _store.newId('SVCMSG'),
      serviceRequestId: requestId,
      senderType: MessageSenderType.customer,
      senderId: customerId,
      message: message,
      createdAt: DateTime.now(),
    );
    _store.serviceMessages.add(customerMessage);

    // Auto-acknowledge so the thread feels alive in a solo demo — a real
    // dealer reply would come from the dealer-side messages screen instead.
    _store.serviceMessages.add(ServiceMessage(
      id: _store.newId('SVCMSG'),
      serviceRequestId: requestId,
      senderType: MessageSenderType.dealer,
      senderId: _currentDealerId(),
      message: "Got it — we'll follow up shortly.",
      createdAt: DateTime.now().add(const Duration(seconds: 1)),
    ));

    return customerMessage;
  }
}
