import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/obd_reading.dart';

/// The standard Bluetooth Serial Port Profile UUID. Every ELM327 clone (and
/// every app/emulator standing in for one over Bluetooth Classic) exposes
/// its serial channel under this UUID — it's not ELM327-specific.
const _sppUuid = '00001101-0000-1000-8000-00805F9B34FB';

/// Talks to a real (or emulated) ELM327 adapter over classic Bluetooth SPP:
/// connects to an already-paired device, runs the standard ELM327 init
/// handshake, then polls a handful of Mode 01 PIDs plus Mode 03 (DTCs) on a
/// timer and turns the responses into [ObdReading]s — the same shape
/// [MockObdService] produces, so nothing downstream cares which one is
/// feeding the dashboard.
///
/// Requires the device to already be paired in the phone's Bluetooth
/// settings; this class only connects, it doesn't scan or pair.
class Elm327Service {
  Elm327Service() : _blueClassic = FlutterBlueClassic();

  final FlutterBlueClassic _blueClassic;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSub;
  Timer? _pollTimer;
  bool _isPolling = false;

  final _controller = StreamController<ObdReading>.broadcast();
  Stream<ObdReading> get stream => _controller.stream;

  final StringBuffer _buffer = StringBuffer();
  Completer<String>? _pending;

  // Some PIDs (voltage) update slower than others don't always respond every
  // tick — hold the last good value so the dashboard doesn't flicker to 0.
  double _lastCoolant = 20;
  double _lastBattery = 12;

  Future<bool> isSupported() => _blueClassic.isSupported;

  /// flutter_blue_classic requests Bluetooth permissions internally, but its
  /// `connect()` (v0.1.1) has a request/response race: it fires off an
  /// async permission request, then checks the result *synchronously* on
  /// the very next line — before the async callback could possibly have
  /// run. If permission isn't already granted, that check sees the still-
  /// unset default, proceeds to connect anyway, and once the OS permission
  /// dialog is actually answered its callback replies to an already-
  /// completed method call — crashing the app ("Reply already submitted").
  ///
  /// Working around it: request everything the plugin might ask for
  /// ourselves, fully, *before* ever calling into it — so by the time it
  /// runs its own internal check, permissions are already granted and it
  /// takes the synchronous "already have it" path with no async race at all.
  Future<bool> _ensurePermissions() async {
    final statuses = await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<List<BluetoothDevice>> pairedDevices() async {
    if (!await _ensurePermissions()) {
      throw StateError(
          'Bluetooth permission was not granted. Enable it for this app in system settings.');
    }
    final devices = await _blueClassic.bondedDevices;
    return devices ?? const [];
  }

  /// Connects to [device], runs the ELM327 init handshake, and starts
  /// polling. Returns null on success, or a human-readable error otherwise
  /// — never throws, so callers can show the message directly.
  Future<String?> connect(BluetoothDevice device) async {
    try {
      await disconnect();

      if (!await _ensurePermissions()) {
        return 'Bluetooth permission was not granted. Enable it for this app in system settings.';
      }

      final connection = await _blueClassic.connect(device.address, uuid: _sppUuid);
      if (connection == null) {
        return "Couldn't open a connection to ${device.name?.isNotEmpty == true ? device.name : device.address}. "
            'Make sure it is still paired and its ELM327/SPP service is running.';
      }
      _connection = connection;
      _buffer.clear();
      _inputSub = connection.input?.listen(_onBytes, onDone: () {
        _pollTimer?.cancel();
        _pollTimer = null;
      });

      // Standard ELM327 init: reset, echo off, linefeeds off, headers off,
      // auto-detect protocol. If it doesn't answer ATZ at all, this almost
      // certainly isn't speaking ELM327 over this channel.
      final resetResponse = await _sendCommand('ATZ', timeout: const Duration(seconds: 3));
      if (resetResponse.trim().isEmpty) {
        await disconnect();
        return 'Connected over Bluetooth, but the device never responded to the ELM327 '
            'reset command (ATZ). Check that the paired device is actually emulating an '
            'ELM327 over its Bluetooth serial channel.';
      }
      for (final cmd in ['ATE0', 'ATL0', 'ATH0', 'ATSP0']) {
        await _sendCommand(cmd);
      }

      _pollTimer = Timer.periodic(const Duration(milliseconds: 900), (_) => _pollOnce());
      return null;
    } catch (e) {
      await disconnect();
      return 'Bluetooth connection failed: $e';
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _inputSub?.cancel();
    _inputSub = null;
    _pending?.completeError(StateError('Disconnected'));
    _pending = null;
    _buffer.clear();
    await _connection?.close();
    _connection = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }

  void _onBytes(Uint8List bytes) {
    _buffer.write(latin1.decode(bytes, allowInvalid: true));
    final text = _buffer.toString();
    final promptIndex = text.indexOf('>');
    if (promptIndex == -1) return;

    final response = text.substring(0, promptIndex);
    _buffer.clear();
    _buffer.write(text.substring(promptIndex + 1));

    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      _pending = null;
      pending.complete(response);
    }
  }

  Future<String> _sendCommand(String command, {Duration timeout = const Duration(seconds: 2)}) async {
    final connection = _connection;
    if (connection == null) return '';

    final completer = Completer<String>();
    _pending = completer;
    connection.writeString('$command\r');

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      if (identical(_pending, completer)) _pending = null;
      return '';
    }
  }

  Future<void> _pollOnce() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final rpmBytes = await _queryPid('010C');
      final coolantBytes = await _queryPid('0105');
      final speedBytes = await _queryPid('010D');
      final throttleBytes = await _queryPid('0111');
      final voltage = await _readVoltage();
      final dtcs = await _readDtcs();

      final rpmValue =
          rpmBytes != null && rpmBytes.length >= 2 ? ((rpmBytes[0] * 256) + rpmBytes[1]) ~/ 4 : 0;
      if (coolantBytes != null && coolantBytes.isNotEmpty) {
        _lastCoolant = (coolantBytes[0] - 40).toDouble();
      }
      final speedValue = speedBytes != null && speedBytes.isNotEmpty ? speedBytes[0].toDouble() : 0.0;
      final throttleValue =
          throttleBytes != null && throttleBytes.isNotEmpty ? throttleBytes[0] * 100 / 255 : 0.0;
      if (voltage != null) _lastBattery = voltage;

      _controller.add(ObdReading(
        timestamp: DateTime.now(),
        rpm: rpmValue,
        coolantTempC: _lastCoolant,
        speedKph: speedValue,
        batteryVoltage: _lastBattery,
        throttlePositionPct: throttleValue,
        activeDtcCodes: dtcs,
      ));
    } finally {
      _isPolling = false;
    }
  }

  /// Sends a Mode 01 PID request (e.g. "010C" for RPM) and returns the data
  /// bytes after the echoed "41 pid" header, or null if unsupported/no data.
  Future<List<int>?> _queryPid(String pid) async {
    final raw = await _sendCommand(pid);
    return _parseModeResponse(raw, expectedPrefix: '41${pid.substring(2)}');
  }

  List<int>? _parseModeResponse(String raw, {required String expectedPrefix}) {
    final hex = raw.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (!hex.startsWith(expectedPrefix)) return null;
    final dataHex = hex.substring(expectedPrefix.length);
    final bytes = <int>[];
    for (var i = 0; i + 2 <= dataHex.length; i += 2) {
      bytes.add(int.parse(dataHex.substring(i, i + 2), radix: 16));
    }
    return bytes.isEmpty ? null : bytes;
  }

  /// ELM327's `ATRV` command reports supply voltage directly as ASCII, e.g.
  /// "12.6V" — no OBD PID for this, it's adapter-specific.
  Future<double?> _readVoltage() async {
    final raw = await _sendCommand('ATRV');
    final match = RegExp(r'([\d.]+)\s*V').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  /// Mode 03 (stored DTCs): each pair of bytes after the "43" header encodes
  /// one code per SAE J2012 — top 2 bits of byte A pick P/C/B/U, remaining
  /// bits are the four digits.
  Future<List<String>> _readDtcs() async {
    final raw = await _sendCommand('03');
    final hex = raw.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    if (!hex.startsWith('43')) return const [];
    final dataHex = hex.substring(2);
    const letters = ['P', 'C', 'B', 'U'];
    final codes = <String>[];
    for (var i = 0; i + 4 <= dataHex.length; i += 4) {
      final b1 = int.parse(dataHex.substring(i, i + 2), radix: 16);
      final b2 = int.parse(dataHex.substring(i + 2, i + 4), radix: 16);
      if (b1 == 0 && b2 == 0) continue;
      final letter = letters[(b1 >> 6) & 0x03];
      final d1 = (b1 >> 4) & 0x03;
      final d2 = b1 & 0x0F;
      final d3 = (b2 >> 4) & 0x0F;
      final d4 = b2 & 0x0F;
      codes.add(('$letter$d1${d2.toRadixString(16)}${d3.toRadixString(16)}${d4.toRadixString(16)}')
          .toUpperCase());
    }
    return codes;
  }
}
