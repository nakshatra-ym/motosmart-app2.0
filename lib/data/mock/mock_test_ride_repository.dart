import '../../core/network/api_exception.dart';
import '../../features/test_rides/data/test_ride_repository.dart';
import '../../models/enums.dart';
import '../../models/test_ride_booking.dart';
import 'mock_data_store.dart';

class MockTestRideRepository implements TestRideRepository {
  MockTestRideRepository(this._store, {required String Function() currentDealerId})
      : _currentDealerId = currentDealerId;

  final MockDataStore _store;
  final String Function() _currentDealerId;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<TestRideBooking>> listTestRides() async {
    await _simulateLatency();
    final dealerId = _currentDealerId();
    final list = _store.testRideBookings.where((b) => b.dealerId == dealerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<TestRideBooking> updateStatus(String id, TestRideStatus status) async {
    await _simulateLatency();
    final index = _store.testRideBookings.indexWhere((b) => b.id == id);
    if (index == -1) throw const ApiException('Test ride booking not found.', statusCode: 404);
    final updated = _store.testRideBookings[index].copyWith(status: status);
    _store.testRideBookings[index] = updated;
    return updated;
  }
}
