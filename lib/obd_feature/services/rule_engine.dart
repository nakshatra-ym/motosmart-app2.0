import '../data/dtc_codes.dart';
import '../models/obd_reading.dart';

/// Deterministic, explainable health scoring.
///
/// This layer answers: "Is this a KNOWN, standardized fault or threshold
/// breach?" It never guesses — every result traces back to either an SAE
/// DTC code or a hard sensor threshold. This is intentionally NOT ML:
/// there is nothing probabilistic to learn here, the "correct answer" is
/// already defined by the OBD-II spec.
///
/// Thresholds below are reasonable generic starting points — recalibrate
/// against real Yamaha ECU data once available (bike engines run hotter/
/// cooler idle ranges than cars depending on cooling type, single vs
/// multi-cylinder, etc).
class RuleEngine {
  // --- Tunable thresholds (recalibrate with real bike data) ---
  static const double coolantHighWarnC = 105;
  static const double coolantHighCriticalC = 115;
  static const double batteryLowWarnV = 11.8;
  static const double batteryLowCriticalV = 11.0;
  static const int rpmRedlineWarn = 9500;

  HealthResult evaluate(ObdReading r) {
    final reasons = <String>[];
    HealthLevel level = HealthLevel.green;

    void escalate(HealthLevel newLevel, String reason) {
      reasons.add(reason);
      if (_rank(newLevel) > _rank(level)) level = newLevel;
    }

    // 1. Active DTCs take priority — they're the most concrete signal.
    for (final code in r.activeDtcCodes) {
      final info = lookupDtc(code);
      escalate(info.severity, '${info.code}: ${info.description}');
    }

    // 2. Threshold-based checks (catch issues even with no DTC yet).
    if (r.coolantTempC >= coolantHighCriticalC) {
      escalate(HealthLevel.red,
          'Coolant temperature critically high (${r.coolantTempC.toStringAsFixed(1)}°C)');
    } else if (r.coolantTempC >= coolantHighWarnC) {
      escalate(HealthLevel.amber,
          'Coolant temperature elevated (${r.coolantTempC.toStringAsFixed(1)}°C)');
    }

    if (r.batteryVoltage <= batteryLowCriticalV) {
      escalate(HealthLevel.red,
          'Battery voltage critically low (${r.batteryVoltage.toStringAsFixed(2)}V)');
    } else if (r.batteryVoltage <= batteryLowWarnV) {
      escalate(HealthLevel.amber,
          'Battery voltage low (${r.batteryVoltage.toStringAsFixed(2)}V)');
    }

    if (r.rpm >= rpmRedlineWarn) {
      escalate(HealthLevel.amber, 'RPM near redline (${r.rpm})');
    }

    return HealthResult(level, reasons);
  }

  int _rank(HealthLevel l) => switch (l) {
        HealthLevel.green => 0,
        HealthLevel.amber => 1,
        HealthLevel.red => 2,
      };
}
