import '../../../models/service_record.dart';
import '../../../models/service_status.dart';
import '../../../models/vehicle.dart';

/// `GET /me/vehicles`, `/vehicles/{id}/service-status`,
/// `/vehicles/{id}/service-history`. Vehicle analytics (OBD telemetry) is
/// intentionally not part of this interface — it's served by
/// `lib/obd_feature/` (a self-contained, already-built module) rather than
/// re-modeled here; see [CustomerHomeScreen].
abstract class VehiclesRepository {
  Future<List<Vehicle>> myVehicles();

  Future<ServiceStatus> serviceStatus(String vehicleId);

  Future<List<ServiceRecord>> serviceHistory(String vehicleId);
}
