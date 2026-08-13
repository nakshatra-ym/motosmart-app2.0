import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../data/mock/mock_vehicles_repository.dart';
import '../../../models/service_record.dart';
import '../../../models/service_status.dart';
import '../../../models/vehicle.dart';
import 'vehicles_repository.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  return MockVehiclesRepository(
    ref.watch(mockDataStoreProvider),
    currentCustomerId: () => ref.read(authControllerProvider).valueOrNull?.customer?.id,
  );
});

final myVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  return ref.watch(vehiclesRepositoryProvider).myVehicles();
});

final serviceStatusProvider =
    FutureProvider.autoDispose.family<ServiceStatus, String>((ref, vehicleId) async {
  return ref.watch(vehiclesRepositoryProvider).serviceStatus(vehicleId);
});

final serviceHistoryProvider =
    FutureProvider.autoDispose.family<List<ServiceRecord>, String>((ref, vehicleId) async {
  return ref.watch(vehiclesRepositoryProvider).serviceHistory(vehicleId);
});
