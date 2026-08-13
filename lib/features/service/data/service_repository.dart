import '../../../models/service_message.dart';
import '../../../models/service_request.dart';

/// `GET/POST /service-requests`, `GET/POST /service-requests/{id}/messages`.
abstract class ServiceRepository {
  Future<List<ServiceRequest>> listRequests();

  Future<ServiceRequest> getRequest(String id);

  Future<ServiceRequest> createRequest({
    required String vehicleId,
    required String type,
    required String description,
    DateTime? preferredDate,
    /// Diagnostics captured from the bike when the ticket was raised from the
    /// OBD dashboard. Attached to the thread and fed to the AI triage.
    String? obdContext,
  });

  Future<List<ServiceMessage>> listMessages(String requestId);

  Future<ServiceMessage> sendMessage(String requestId, String message);
}
