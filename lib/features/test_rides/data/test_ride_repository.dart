import '../../../models/enums.dart';
import '../../../models/test_ride_booking.dart';

/// Dealer-side view of test-ride bookings: `GET /test-rides`,
/// `PATCH /test-rides/{id}` (confirm/complete).
abstract class TestRideRepository {
  Future<List<TestRideBooking>> listTestRides();

  Future<TestRideBooking> updateStatus(String id, TestRideStatus status);
}
