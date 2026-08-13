import '../../core/network/api_client.dart';
import '../../features/vehicles/data/vehicles_repository.dart';
import '../../models/service_record.dart';
import '../../models/service_status.dart';
import '../../models/vehicle.dart';

/// The customer's garage: `GET /me/vehicles`, plus per-vehicle service status
/// and history.
class ApiVehiclesRepository implements VehiclesRepository {
  const ApiVehiclesRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Vehicle>> myVehicles() async {
    final rows = await _api.getList('/me/vehicles');
    return rows.map(Vehicle.fromJson).toList();
  }

  @override
  Future<ServiceStatus> serviceStatus(String vehicleId) async {
    return ServiceStatus.fromJson(
      await _api.getObject('/vehicles/$vehicleId/service-status'),
    );
  }

  @override
  Future<List<ServiceRecord>> serviceHistory(String vehicleId) async {
    final rows = await _api.getList('/vehicles/$vehicleId/service-history');
    return rows.map(ServiceRecord.fromJson).toList();
  }
}
