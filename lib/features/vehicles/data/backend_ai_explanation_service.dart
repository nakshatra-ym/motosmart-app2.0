import '../../../core/network/api_client.dart';
import '../../../models/json_utils.dart';
import '../../../obd_feature/data/dtc_codes.dart';
import '../../../obd_feature/models/obd_reading.dart';
import '../../../obd_feature/services/ai_explanation_service.dart';

/// Routes the OBD dashboard's fault explanations through our backend instead of
/// calling Anthropic directly from the device.
///
/// `lib/obd_feature/` ships an [AiExplanationService] that posts to the Anthropic
/// API with a key baked into the build. That key is empty here (and shipping one
/// would be wrong), so the card always fell back to the raw technical text —
/// "AI explanation unavailable". Subclassing and overriding the one method keeps
/// the OBD module **completely untouched**, including all of its Bluetooth code,
/// while the model call happens server-side on Bedrock.
///
/// Falls back to the parent's deterministic description if the request fails, so
/// the card behaves exactly as before when the backend is unreachable.
class BackendAiExplanationService extends AiExplanationService {
  BackendAiExplanationService({
    required this.api,
    required this.vehicleId,
  }) : super(apiKey: '');

  final ApiClient api;

  /// Needed for the ownership check on the endpoint.
  final String vehicleId;

  @override
  Future<String> explainFault(String dtcCode, ObdReading reading) async {
    try {
      final response = await api.post(
        '/vehicles/$vehicleId/dtc-explanation',
        body: {
          'dtc_code': dtcCode,
          'technical_description': lookupDtc(dtcCode).description,
          'rpm': reading.rpm,
          'coolant_temp_c': reading.coolantTempC,
          'speed_kph': reading.speedKph,
          'battery_voltage': reading.batteryVoltage,
          'throttle_position_pct': reading.throttlePositionPct,
          'fuel_level_pct': reading.fuelLevelPct,
          'dtc_codes': reading.activeDtcCodes,
        },
      );
      final explanation = asString(response['explanation']);
      if (explanation.isNotEmpty) return explanation;
    } catch (_) {
      // Deliberately swallowed: a failed explanation must never break the
      // dashboard mid-ride. The parent's technical description stands in.
    }
    return super.explainFault(dtcCode, reading);
  }
}
