import '../../core/network/api_client.dart';
import '../../features/test_rides/data/test_ride_repository.dart';
import '../../models/enums.dart';
import '../../models/test_ride_booking.dart';

/// Dealer-side test-ride queue: `GET /test-rides`, `PATCH /test-rides/{id}`.
class ApiTestRideRepository implements TestRideRepository {
  const ApiTestRideRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<TestRideBooking>> listTestRides() async {
    final rows = await _api.getList('/test-rides', query: {'limit': 200});
    return rows.map(TestRideBooking.fromJson).toList();
  }

  @override
  Future<TestRideBooking> updateStatus(String id, TestRideStatus status) async {
    final response =
        await _api.patch('/test-rides/$id', body: {'status': status.value});
    return TestRideBooking.fromJson(response);
  }
}
