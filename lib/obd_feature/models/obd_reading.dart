/// A single snapshot of OBD telemetry at one point in time.
///
/// This is the ONE shape of data that flows through the entire feature —
/// mock generator, CSV replay, and (later) real BLE/BT ELM327 data should
/// all produce this same object, so nothing downstream needs to change
/// when you swap the data source.
class ObdReading {
  final DateTime timestamp;
  final int rpm;
  final double coolantTempC;
  final double speedKph;
  final double batteryVoltage;
  final double throttlePositionPct;
  final double fuelLevelPct;
  final List<String> activeDtcCodes;

  const ObdReading({
    required this.timestamp,
    required this.rpm,
    required this.coolantTempC,
    required this.speedKph,
    required this.batteryVoltage,
    required this.throttlePositionPct,
    this.fuelLevelPct = 100,
    this.activeDtcCodes = const [],
  });

  ObdReading copyWith({
    DateTime? timestamp,
    int? rpm,
    double? coolantTempC,
    double? speedKph,
    double? batteryVoltage,
    double? throttlePositionPct,
    double? fuelLevelPct,
    List<String>? activeDtcCodes,
  }) {
    return ObdReading(
      timestamp: timestamp ?? this.timestamp,
      rpm: rpm ?? this.rpm,
      coolantTempC: coolantTempC ?? this.coolantTempC,
      speedKph: speedKph ?? this.speedKph,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      throttlePositionPct: throttlePositionPct ?? this.throttlePositionPct,
      fuelLevelPct: fuelLevelPct ?? this.fuelLevelPct,
      activeDtcCodes: activeDtcCodes ?? this.activeDtcCodes,
    );
  }

  factory ObdReading.empty() => ObdReading(
        timestamp: DateTime.now(),
        rpm: 0,
        coolantTempC: 0,
        speedKph: 0,
        batteryVoltage: 0,
        throttlePositionPct: 0,
      );

  @override
  String toString() =>
      'ObdReading(rpm: $rpm, coolant: $coolantTempC°C, speed: $speedKph km/h, '
      'batt: ${batteryVoltage}V, dtc: $activeDtcCodes)';
}

/// Health status derived from a reading by the rule engine.
enum HealthLevel { green, amber, red }

class HealthResult {
  final HealthLevel level;
  final List<String> reasons; // human-readable reasons for the level

  const HealthResult(this.level, this.reasons);

  factory HealthResult.healthy() => const HealthResult(HealthLevel.green, []);
}
