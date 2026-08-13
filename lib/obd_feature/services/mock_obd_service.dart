import 'dart:async';
import 'dart:math';

import '../models/obd_reading.dart';

/// Emits ObdReading objects on a timer, simulating a live bike.
///
/// SWAP POINT: when real BT/BLE hardware works, replace this class with
/// one that parses ELM327 responses into ObdReading — nothing else in
/// the app needs to change, since everything downstream consumes the
/// same Stream<ObdReading>.
///
/// Includes scripted "events" so you can reliably demo the alert/health
/// logic firing on cue instead of hoping randomness cooperates live.
class MockObdService {
  final _controller = StreamController<ObdReading>.broadcast();
  Timer? _timer;
  final Random _rand = Random();

  double _coolant = 45; // starts cool, warms up like a real engine
  double _battery = 12.6;
  int _tick = 0;

  Stream<ObdReading> get stream => _controller.stream;

  /// Optional scripted DTC events: tick number -> DTC codes to inject.
  /// Lets you trigger a fault reliably during a live demo by calling
  /// [triggerFault] on a button press instead of waiting for randomness.
  final Map<int, List<String>> _scriptedEvents = {};

  void start({Duration interval = const Duration(milliseconds: 800)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _emit());
  }

  void stop() => _timer?.cancel();

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }

  /// Call this from a demo "inject fault" button to fire a specific DTC
  /// on the very next tick — much safer for live judging than relying on
  /// random chance to show the alert flow.
  List<String> _pendingFault = [];
  void triggerFault(List<String> dtcCodes) {
    _pendingFault = dtcCodes;
  }

  void clearFault() {
    _pendingFault = [];
  }

  void _emit() {
    _tick++;

    // Engine warms up toward a normal operating band, with small noise.
    _coolant += (_coolant < 90 ? 0.6 : 0) + (_rand.nextDouble() - 0.5) * 0.4;
    _coolant = _coolant.clamp(20, 130);

    // Battery drifts gently; occasional small sag under load.
    _battery += (_rand.nextDouble() - 0.5) * 0.05;
    _battery = _battery.clamp(10.5, 13.2);

    final rpm = 1200 + _rand.nextInt(3500);
    final speed = (rpm / 120).clamp(0, 140).toDouble();
    final throttle = _rand.nextDouble() * 60;

    final dtcs = _pendingFault.isNotEmpty
        ? List<String>.from(_pendingFault)
        : (_scriptedEvents[_tick] ?? const <String>[]);

    _controller.add(ObdReading(
      timestamp: DateTime.now(),
      rpm: rpm,
      coolantTempC: _coolant,
      speedKph: speed,
      batteryVoltage: _battery,
      throttlePositionPct: throttle,
      activeDtcCodes: dtcs,
    ));
  }
}
