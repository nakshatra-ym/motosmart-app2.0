import '../../../obd_feature/models/obd_reading.dart';

/// Keeps the last [window] of readings in memory while the monitor screen is
/// open, so an AI summary can describe how the bike behaved over that period
/// instead of at a single instant.
///
/// Lives in the app layer and is fed by listening to `DashboardProvider` — the
/// OBD module is not asked to remember anything, and nothing about the Bluetooth
/// path changes. Bounded twice over (by age and by [maxSamples]) so a long
/// session cannot grow it without limit.
class TelemetryBuffer {
  TelemetryBuffer({
    this.window = const Duration(minutes: 1),
    this.maxSamples = 600,
  });

  final Duration window;

  /// Hard cap in case a device streams far faster than once a second.
  final int maxSamples;

  final _samples = <ObdReading>[];

  int get length => _samples.length;
  bool get isEmpty => _samples.isEmpty;

  /// Oldest-first, pruned to the window.
  List<ObdReading> get samples => List.unmodifiable(_samples);

  /// The period actually covered, which is shorter than [window] until the
  /// buffer has filled.
  Duration get span => _samples.length < 2
      ? Duration.zero
      : _samples.last.timestamp.difference(_samples.first.timestamp);

  /// Appends a reading, ignoring repeats.
  ///
  /// `DashboardProvider` notifies on other state changes too (connection status,
  /// AI explanation arriving), so the same reading can arrive several times;
  /// de-duplicating on the timestamp keeps the statistics honest.
  void add(ObdReading reading) {
    if (_samples.isNotEmpty &&
        _samples.last.timestamp.isAtSameMomentAs(reading.timestamp)) {
      return;
    }
    _samples.add(reading);
    _prune(reading.timestamp);
  }

  void clear() => _samples.clear();

  void _prune(DateTime now) {
    final cutoff = now.subtract(window);
    _samples.removeWhere((s) => s.timestamp.isBefore(cutoff));
    if (_samples.length > maxSamples) {
      _samples.removeRange(0, _samples.length - maxSamples);
    }
  }

  /// The window as the API expects it: each sample's age in seconds relative to
  /// [now], so the server never has to trust the device's clock.
  List<Map<String, dynamic>> toJson({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return [
      for (final s in _samples)
        {
          'age_seconds': reference.difference(s.timestamp).inMilliseconds / 1000.0,
          'rpm': s.rpm,
          'coolant_temp_c': s.coolantTempC,
          'speed_kph': s.speedKph,
          'battery_voltage': s.batteryVoltage,
          'throttle_position_pct': s.throttlePositionPct,
          'fuel_level_pct': s.fuelLevelPct,
        },
    ];
  }
}
