import '../../core/network/api_client.dart';
import '../../features/public/data/public_repository.dart';
import '../../models/bike_model.dart';
import '../../models/exchange_estimate.dart';
import '../../models/json_utils.dart';
import '../../models/test_ride_booking.dart';

/// The unauthenticated guest funnel: `/public/*`.
///
/// These calls still go through the shared dio instance. That is harmless — the
/// auth interceptor only attaches a header when a token happens to be stored,
/// and the `/public/*` routes ignore it either way.
class ApiPublicRepository implements PublicRepository {
  const ApiPublicRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<BikeModel>> listModels() async {
    final rows = await _api.getList(
      '/public/models',
      // Show the whole range and let the card render "out of stock", rather
      // than hiding models the customer came looking for.
      query: {'available_only': false, 'limit': 100},
    );
    return rows.map(BikeModel.fromJson).toList();
  }

  @override
  Future<BikeModel> getModel(String id) async {
    return BikeModel.fromJson(await _api.getObject('/public/models/$id'));
  }

  @override
  Future<ExchangeEstimate> estimateExchangeValue({
    required String brand,
    required String model,
    required int year,
    required String condition,
  }) async {
    final response = await _api.post('/public/exchange-value', body: {
      'brand': brand,
      'model': model,
      'year': year,
      'condition': condition.toUpperCase(),
    });
    return ExchangeEstimate.fromJson(response);
  }

  @override
  Future<bool> checkAvailability(String modelId) async {
    final response =
        await _api.getObject('/public/availability', query: {'model_id': modelId});
    return response['is_available'] as bool? ?? false;
  }

  @override
  Future<TestRideBooking> bookTestRide({
    required String bikeModelId,
    required String name,
    required String mobile,
    required DateTime preferredDate,
    required String preferredTime,
  }) async {
    final response = await _api.post('/public/test-rides', body: {
      'bike_model_id': bikeModelId,
      'name': name,
      'mobile': mobile,
      'preferred_date': dateOnly(preferredDate),
      if (preferredTime.isNotEmpty) 'preferred_time': _asApiTime(preferredTime),
      // No dealer/pincode is sent: this booking form has no location picker, so
      // the backend's `resolve_dealer` falls through to its deterministic
      // default branch. A booking is never dropped for want of a dealer.
    });
    // The response wraps the booking alongside the lead it generated.
    return TestRideBooking.fromJson(asMap(response['booking']));
  }

  /// The API parses `preferred_time` as a `time`, which needs `HH:MM`. The UI
  /// may hand over `9:30` or `09:30 AM`, so this normalises to 24-hour `HH:MM`
  /// and gives up (sending nothing rather than something invalid) if it can't.
  String _asApiTime(String raw) {
    final text = raw.trim().toUpperCase();
    final match = RegExp(r'^(\d{1,2})[:.](\d{2})\s*(AM|PM)?').firstMatch(text);
    if (match == null) return raw.trim();
    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = match.group(2)!;
    final meridiem = match.group(3);
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }
}
