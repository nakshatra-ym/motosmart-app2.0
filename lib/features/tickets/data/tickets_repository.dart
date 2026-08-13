import '../../../models/enums.dart';
import '../../../models/service_message.dart';
import '../../../models/service_request.dart';

/// Dealer-side view of customer-raised service tickets:
/// `GET /service-requests?dealer_id=`, `PATCH /service-requests/{id}`,
/// `GET/POST /service-requests/{id}/messages`.
abstract class TicketsRepository {
  Future<List<ServiceRequest>> listTickets();

  Future<ServiceRequest> getTicket(String id);

  Future<ServiceRequest> updateStatus(String id, ServiceRequestStatus status);

  Future<List<ServiceMessage>> listMessages(String ticketId);

  Future<ServiceMessage> sendMessage(String ticketId, String message);
}
