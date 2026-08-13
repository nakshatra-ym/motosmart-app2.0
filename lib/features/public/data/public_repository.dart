import '../../../models/bike_model.dart';
import '../../../models/exchange_estimate.dart';
import '../../../models/test_ride_booking.dart';

/// Mirrors PLAN_backend.md's unauthenticated `/public/*` routers — the
/// guest browsing funnel. No auth token is attached for these calls.
abstract class PublicRepository {
  Future<List<BikeModel>> listModels();

  Future<BikeModel> getModel(String id);

  Future<ExchangeEstimate> estimateExchangeValue({
    required String brand,
    required String model,
    required int year,
    required String condition,
  });

  Future<bool> checkAvailability(String modelId);

  /// `POST /public/test-rides` — auto-creates and auto-assigns a lead
  /// server-side (see PLAN_backend.md's round-robin assignment algorithm).
  Future<TestRideBooking> bookTestRide({
    required String bikeModelId,
    required String name,
    required String mobile,
    required DateTime preferredDate,
    required String preferredTime,
  });
}
