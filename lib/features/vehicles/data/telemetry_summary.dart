import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../models/json_utils.dart';

/// What `POST /vehicles/{id}/telemetry-summary` returns: a plain-language read
/// of the gauges, plus whether it is worth opening a service request.
class TelemetrySummary {
  const TelemetrySummary({
    required this.summary,
    required this.source,
    required this.isActionable,
    this.suggestedType,
    this.suggestedDescription,
    this.obdContext,
    this.samplesUsed = 0,
    this.windowSeconds,
  });

  final String summary;

  /// `'bedrock'` for a real model answer, `'fallback'` for the deterministic
  /// rule-based one. Surfaced in the UI so a demo never claims AI it didn't use.
  final String source;

  /// True when the readings show something a dealer should look at — this is
  /// what reveals the "raise a ticket" button.
  final bool isActionable;

  final String? suggestedType;
  final String? suggestedDescription;

  /// The readings formatted for attaching to a service request thread.
  final String? obdContext;

  /// How many buffered samples the summary was computed from, and the period
  /// they covered — shown so the rider knows it read a minute, not one instant.
  final int samplesUsed;
  final int? windowSeconds;

  bool get isAiGenerated => source == 'bedrock';

  factory TelemetrySummary.fromJson(Map<String, dynamic> json) => TelemetrySummary(
        summary: asString(json['summary']),
        source: asString(json['source'], fallback: 'fallback'),
        isActionable: json['is_actionable'] as bool? ?? false,
        suggestedType: json['suggested_type'] as String?,
        suggestedDescription: json['suggested_description'] as String?,
        obdContext: json['obd_context'] as String?,
        samplesUsed: asInt(json['samples_used']),
        windowSeconds: asIntOrNull(json['window_seconds']),
      );
}

/// The readings currently on the OBD dashboard, whatever their source (the
/// in-app simulator or a connected ELM327 device).
class TelemetryReadings {
  const TelemetryReadings({
    this.rpm,
    this.coolantTempC,
    this.speedKph,
    this.batteryVoltage,
    this.throttlePositionPct,
    this.fuelLevelPct,
    this.odometerKm,
    this.dtcCodes = const [],
    this.healthLevel,
    this.healthReasons = const [],
    this.samples = const [],
    this.windowSeconds,
  });

  final int? rpm;
  final double? coolantTempC;
  final double? speedKph;
  final double? batteryVoltage;
  final double? throttlePositionPct;
  final double? fuelLevelPct;
  final int? odometerKm;
  final List<String> dtcCodes;

  /// The on-device rule engine's verdict (`green` / `amber` / `red`), sent so the
  /// summary agrees with the badge the rider can already see.
  final String? healthLevel;
  final List<String> healthReasons;

  /// The buffered window (oldest first), each entry carrying its `age_seconds`.
  /// The server turns these into min/max/avg/trend statistics.
  final List<Map<String, dynamic>> samples;
  final int? windowSeconds;

  Map<String, dynamic> toJson() => {
        if (rpm != null) 'rpm': rpm,
        if (coolantTempC != null) 'coolant_temp_c': coolantTempC,
        if (speedKph != null) 'speed_kph': speedKph,
        if (batteryVoltage != null) 'battery_voltage': batteryVoltage,
        if (throttlePositionPct != null) 'throttle_position_pct': throttlePositionPct,
        if (fuelLevelPct != null) 'fuel_level_pct': fuelLevelPct,
        if (odometerKm != null) 'odometer_km': odometerKm,
        'dtc_codes': dtcCodes,
        if (healthLevel != null) 'health_level': healthLevel,
        'health_reasons': healthReasons,
        if (samples.isNotEmpty) 'samples': samples,
        if (windowSeconds != null) 'window_seconds': windowSeconds,
      };
}

/// Summarises the readings on the dashboard. Widgets depend on this interface,
/// never on an implementation.
abstract class TelemetrySummaryRepository {
  Future<TelemetrySummary> summarise({
    required String vehicleId,
    required TelemetryReadings readings,
  });
}

/// Real implementation. The model call happens server side (Bedrock), so no AI
/// credentials ship in the app.
class ApiTelemetrySummaryRepository implements TelemetrySummaryRepository {
  const ApiTelemetrySummaryRepository(this._api);

  final ApiClient _api;

  @override
  Future<TelemetrySummary> summarise({
    required String vehicleId,
    required TelemetryReadings readings,
  }) async {
    final response = await _api.post(
      '/vehicles/$vehicleId/telemetry-summary',
      body: readings.toJson(),
    );
    return TelemetrySummary.fromJson(response);
  }
}

/// Mock-mode stand-in: describes the same readings without a backend, so the
/// offline demo still shows a summary card.
class MockTelemetrySummaryRepository implements TelemetrySummaryRepository {
  const MockTelemetrySummaryRepository();

  @override
  Future<TelemetrySummary> summarise({
    required String vehicleId,
    required TelemetryReadings readings,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final faults = <String>[
      if (readings.dtcCodes.isNotEmpty)
        'fault code(s) ${readings.dtcCodes.join(', ')}',
      if ((readings.coolantTempC ?? 0) >= 105) 'coolant is high',
      if ((readings.batteryVoltage ?? 13) < 12) 'battery voltage is low',
    ];
    final parts = <String>[
      if (readings.rpm != null) 'engine at ${readings.rpm} rpm',
      if (readings.speedKph != null) '${readings.speedKph!.toStringAsFixed(0)} km/h',
      if (readings.coolantTempC != null)
        'coolant ${readings.coolantTempC!.toStringAsFixed(0)}°C',
      if (readings.batteryVoltage != null)
        'battery ${readings.batteryVoltage!.toStringAsFixed(2)}V',
    ];
    return TelemetrySummary(
      summary: 'Current readings: ${parts.join(', ')}.'
          '${faults.isEmpty ? ' Everything is in the normal range.' : ' Attention: ${faults.join('; ')}.'}',
      source: 'fallback',
      isActionable: faults.isNotEmpty,
      suggestedType: faults.isEmpty ? null : 'General service',
      suggestedDescription: faults.isEmpty
          ? null
          : 'Raised from the bike health dashboard. Detected: ${faults.join('; ')}.',
      obdContext: faults.isEmpty ? null : 'Readings: ${parts.join(', ')}',
    );
  }
}

final telemetrySummaryRepositoryProvider = Provider<TelemetrySummaryRepository>((ref) {
  if (ref.watch(useMockDataProvider)) return const MockTelemetrySummaryRepository();
  return ApiTelemetrySummaryRepository(ref.watch(apiClientProvider));
});
