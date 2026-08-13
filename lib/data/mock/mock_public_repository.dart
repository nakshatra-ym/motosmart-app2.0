import '../../core/network/api_exception.dart';
import '../../features/public/data/public_repository.dart';
import '../../models/bike_model.dart';
import '../../models/exchange_estimate.dart';
import '../../models/test_ride_booking.dart';
import 'mock_data_store.dart';

class MockPublicRepository implements PublicRepository {
  MockPublicRepository(this._store);

  final MockDataStore _store;

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 350));

  @override
  Future<List<BikeModel>> listModels() async {
    await _simulateLatency();
    return List.unmodifiable(_store.bikeModels);
  }

  @override
  Future<BikeModel> getModel(String id) async {
    await _simulateLatency();
    final model = _store.bikeModelById(id);
    if (model == null) throw const ApiException('Model not found.', statusCode: 404);
    return model;
  }

  @override
  Future<bool> checkAvailability(String modelId) async {
    await _simulateLatency();
    return _store.bikeModelById(modelId)?.isAvailable ?? false;
  }

  @override
  Future<ExchangeEstimate> estimateExchangeValue({
    required String brand,
    required String model,
    required int year,
    required String condition,
  }) async {
    await _simulateLatency();
    final age = DateTime.now().year - year;
    final conditionFactor = switch (condition.toLowerCase()) {
      'excellent' => 1.0,
      'good' => 0.85,
      'fair' => 0.65,
      _ => 0.5,
    };
    final baseValue = 95000 - (age.clamp(0, 12) * 7000);
    final estimated = (baseValue * conditionFactor).clamp(8000, 95000).toDouble();

    return ExchangeEstimate(
      brand: brand,
      model: model,
      year: year,
      estimatedValue: estimated,
      note: 'Indicative estimate only — final value confirmed by the dealer after inspection.',
    );
  }

  @override
  Future<TestRideBooking> bookTestRide({
    required String bikeModelId,
    required String name,
    required String mobile,
    required DateTime preferredDate,
    required String preferredTime,
  }) async {
    await _simulateLatency();
    return _store.bookTestRide(
      bikeModelId: bikeModelId,
      name: name,
      mobile: mobile,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
    );
  }
}
