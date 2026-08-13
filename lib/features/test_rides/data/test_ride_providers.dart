import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/api/api_test_ride_repository.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../data/mock/mock_test_ride_repository.dart';
import '../../../models/test_ride_booking.dart';
import 'test_ride_repository.dart';

final testRideRepositoryProvider = Provider<TestRideRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockTestRideRepository(
      ref.watch(mockDataStoreProvider),
      currentDealerId: () =>
          ref.read(authControllerProvider).valueOrNull?.employee?.dealerId ?? '',
    );
  }
  return ApiTestRideRepository(ref.watch(apiClientProvider));
});

final testRidesListProvider = FutureProvider.autoDispose<List<TestRideBooking>>((ref) async {
  return ref.watch(testRideRepositoryProvider).listTestRides();
});
