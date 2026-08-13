import '../../core/network/api_exception.dart';
import '../../features/vehicles/data/vehicles_repository.dart';
import '../../models/service_record.dart';
import '../../models/service_status.dart';
import '../../models/vehicle.dart';
import 'mock_data_store.dart';

class MockVehiclesRepository implements VehiclesRepository {
  MockVehiclesRepository(this._store, {required String? Function() currentCustomerId})
      : _currentCustomerId = currentCustomerId;

  final MockDataStore _store;
  final String? Function() _currentCustomerId;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<Vehicle>> myVehicles() async {
    await _simulateLatency();
    final customerId = _currentCustomerId();
    if (customerId == null) return const [];
    return _store.vehiclesForCustomer(customerId);
  }

  Vehicle _findVehicle(String vehicleId) {
    try {
      return _store.vehicles.firstWhere((v) => v.id == vehicleId);
    } catch (_) {
      throw const ApiException('Vehicle not found.', statusCode: 404);
    }
  }

  @override
  Future<ServiceStatus> serviceStatus(String vehicleId) async {
    await _simulateLatency();
    final vehicle = _findVehicle(vehicleId);
    final records = _store.serviceRecords.where((r) => r.vehicleId == vehicleId).toList()
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
  Future<List<ServiceRecord>> serviceHistory(String vehicleId) async {
    await _simulateLatency();
    final list = _store.serviceRecords.where((r) => r.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return list;
  }
}
