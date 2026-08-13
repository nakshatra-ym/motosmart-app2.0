import '../../../obd_feature/services/mock_obd_service.dart';

/// A feed that emits nothing, so the dashboard shows **no data until a real
/// ELM327 is connected**.
///
/// `DashboardProvider` takes a [MockObdService] and calls `start()` on it in its
/// constructor, which would otherwise stream invented readings. Subclassing and
/// making `start()` a no-op removes the simulated data without touching a single
/// line inside `lib/obd_feature/` — the Bluetooth path is untouched, and
/// `connectToDevice()` still calls `stop()` on this object harmlessly before
/// swapping in the live stream.
///
/// `triggerFault`/`clearFault` are also neutered: with nothing emitting, there is
/// no reading to attach an injected fault to, and fabricated faults are exactly
/// what we are removing.
class IdleObdService extends MockObdService {
  @override
  void start({Duration interval = const Duration(milliseconds: 800)}) {
    // Intentionally empty — readings come from the bike, or not at all.
  }

  @override
  void triggerFault(List<String> dtcCodes) {
    // No-op: no simulated readings to inject a fault into.
  }
}
