import '../../core/network/api_client.dart';
import '../../features/service/data/service_repository.dart';
import '../../models/json_utils.dart';
import '../../models/service_message.dart';
import '../../models/service_request.dart';

/// Service-request threads: `/service-requests` and their message sub-resource.
/// The API scopes the list by role, so a customer sees their own requests and
/// dealer staff see their branch's.
class ApiServiceRepository implements ServiceRepository {
  const ApiServiceRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ServiceRequest>> listRequests() async {
    final rows = await _api.getList('/service-requests', query: {'limit': 200});
    return rows.map(ServiceRequest.fromJson).toList();
  }

  @override
  Future<ServiceRequest> getRequest(String id) async {
    return ServiceRequest.fromJson(await _api.getObject('/service-requests/$id'));
  }

  @override
  Future<ServiceRequest> createRequest({
    required String vehicleId,
    required String type,
    required String description,
    DateTime? preferredDate,
    String? obdContext,
  }) async {
    final response = await _api.post('/service-requests', body: {
      'vehicle_id': vehicleId,
      'type': type,
      'description': description,
      if (preferredDate != null) 'preferred_date': dateOnly(preferredDate),
      if (obdContext != null && obdContext.isNotEmpty) 'obd_context': obdContext,
    });
    return ServiceRequest.fromJson(response);
  }

  @override
  Future<List<ServiceMessage>> listMessages(String requestId) async {
    final rows = await _api.getList('/service-requests/$requestId/messages');
    return rows.map(ServiceMessage.fromJson).toList();
  }

  @override
  Future<ServiceMessage> sendMessage(String requestId, String message) async {
    final response = await _api.post(
      '/service-requests/$requestId/messages',
      body: {'message': message},
    );
    return ServiceMessage.fromJson(response);
  }
}
