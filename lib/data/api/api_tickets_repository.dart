import '../../core/network/api_client.dart';
import '../../features/tickets/data/tickets_repository.dart';
import '../../models/enums.dart';
import '../../models/service_message.dart';
import '../../models/service_request.dart';

/// Dealer-side view of the same `/service-requests` resource the customer uses.
/// No dealer filter is passed: the API already scopes the list by the caller's
/// role, returning the branch's requests for dealer staff.
class ApiTicketsRepository implements TicketsRepository {
  const ApiTicketsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ServiceRequest>> listTickets() async {
    final rows = await _api.getList('/service-requests', query: {'limit': 200});
    return rows.map(ServiceRequest.fromJson).toList();
  }

  @override
  Future<ServiceRequest> getTicket(String id) async {
    return ServiceRequest.fromJson(await _api.getObject('/service-requests/$id'));
  }

  @override
  Future<ServiceRequest> updateStatus(String id, ServiceRequestStatus status) async {
    final response =
        await _api.patch('/service-requests/$id', body: {'status': status.value});
    return ServiceRequest.fromJson(response);
  }

  @override
  Future<List<ServiceMessage>> listMessages(String ticketId) async {
    final rows = await _api.getList('/service-requests/$ticketId/messages');
    return rows.map(ServiceMessage.fromJson).toList();
  }

  @override
  Future<ServiceMessage> sendMessage(String ticketId, String message) async {
    final response = await _api.post(
      '/service-requests/$ticketId/messages',
      body: {'message': message},
    );
    return ServiceMessage.fromJson(response);
  }
}
