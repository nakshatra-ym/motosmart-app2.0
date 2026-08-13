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
  });

  Future<List<ServiceMessage>> listMessages(String requestId);

  Future<ServiceMessage> sendMessage(String requestId, String message);
}
