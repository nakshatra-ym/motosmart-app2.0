import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart' show BluetoothDevice;

import '../models/obd_reading.dart';
import '../services/mock_obd_service.dart';
import '../services/elm327_service.dart';
import '../services/rule_engine.dart';
import '../services/ai_explanation_service.dart';

/// Central state for the dashboard. Combines:
/// - the live data stream (simulated by default, or a real ELM327 over
///   Bluetooth once [connectToDevice] succeeds)
/// - the instant rule-based health result
/// - the async AI-generated plain-language explanation
///
/// UI widgets just listen to this via Provider/Consumer — they don't know
/// or care where the data actually came from.
class DashboardProvider extends ChangeNotifier {
  final MockObdService _mockService;
  final Elm327Service _elm327Service;
  final RuleEngine _ruleEngine = RuleEngine();
  final AiExplanationService _aiService;

  StreamSubscription<ObdReading>? _sub;

  ObdReading latestReading = ObdReading.empty();
  HealthResult health = HealthResult.healthy();

  String? aiExplanation;
  bool aiLoading = false;

  /// True once [connectToDevice] has swapped the feed from simulated to a
  /// real Bluetooth ELM327 connection.
  bool isLive = false;
  bool isConnecting = false;
  String? liveDeviceName;
  String? connectionError;

  List<String> _lastDtcSeen = [];

  DashboardProvider({
    required MockObdService obdService,
    required AiExplanationService aiService,
    Elm327Service? elm327Service,
  })  : _mockService = obdService,
        _elm327Service = elm327Service ?? Elm327Service(),
        _aiService = aiService {
    _sub = _mockService.stream.listen(_onReading);
    _mockService.start();
  }

  Future<bool> get isBluetoothAvailable => _elm327Service.isSupported();

  Future<List<BluetoothDevice>> get pairedDevices => _elm327Service.pairedDevices();

  /// Connects to a real ELM327 (or emulator) over Bluetooth SPP and, on
  /// success, swaps the dashboard's feed from simulated to live — nothing
  /// in [_onReading] or the widgets downstream needs to know the difference.
  Future<void> connectToDevice(BluetoothDevice device) async {
    isConnecting = true;
    connectionError = null;
    notifyListeners();

    final error = await _elm327Service.connect(device);
    if (error != null) {
      isConnecting = false;
      connectionError = error;
      notifyListeners();
      return;
    }

    _mockService.stop();
    await _sub?.cancel();
    _sub = _elm327Service.stream.listen(_onReading);

    isConnecting = false;
    isLive = true;
    liveDeviceName = (device.name?.isNotEmpty ?? false) ? device.name : device.address;
    notifyListeners();
  }

  /// Drops the live connection and falls back to simulated data.
  Future<void> disconnectDevice() async {
    await _elm327Service.disconnect();
    await _sub?.cancel();
    isLive = false;
    liveDeviceName = null;
    latestReading = ObdReading.empty();
    _sub = _mockService.stream.listen(_onReading);
    _mockService.start();
    notifyListeners();
  }

  void _onReading(ObdReading reading) {
    latestReading = reading;
    health = _ruleEngine.evaluate(reading);

    // Only call the AI layer when the DTC set actually changes — no point
    // spamming an API call on every single tick, and it keeps the demo
    // visibly showing "instant rules, then AI catches up" as designed.
    final dtcChanged =
        !_listEquals(reading.activeDtcCodes, _lastDtcSeen) &&
            reading.activeDtcCodes.isNotEmpty;

    if (dtcChanged) {
      _lastDtcSeen = List.from(reading.activeDtcCodes);
      _fetchAiExplanation(reading.activeDtcCodes.first, reading);
    } else if (reading.activeDtcCodes.isEmpty && _lastDtcSeen.isNotEmpty) {
      _lastDtcSeen = [];
      aiExplanation = null;
    }

    notifyListeners();
  }

  Future<void> _fetchAiExplanation(String dtcCode, ObdReading reading) async {
    aiLoading = true;
    aiExplanation = null;
    notifyListeners();

    final explanation = await _aiService.explainFault(dtcCode, reading);

    aiLoading = false;
    aiExplanation = explanation;
    notifyListeners();
  }

  /// Manually fire a fault — wire this to a demo button so you can
  /// reliably trigger the alert flow on cue during judging. Only has an
  /// effect while running on simulated data.
  void injectFault(List<String> dtcCodes) {
    _mockService.triggerFault(dtcCodes);
  }

  void clearFault() {
    _mockService.clearFault();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mockService.dispose();
    _elm327Service.dispose();
    super.dispose();
  }
}
