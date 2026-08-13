import '../models/obd_reading.dart';

/// A single DTC (Diagnostic Trouble Code) definition.
class DtcInfo {
  final String code;
  final String description;
  final HealthLevel severity;

  const DtcInfo(this.code, this.description, this.severity);
}

/// Static lookup table of common SAE-standard generic DTCs.
/// These codes are standardized across manufacturers (incl. two-wheelers
/// with OBD-II), so this table doesn't need to be Yamaha-specific to be
/// factually correct. Extend with Yamaha manufacturer-specific codes
/// (Pxxxx in the 1000-3000 range, varies by ECU) once you have real fault
/// data from the bike.
final Map<String, DtcInfo> dtcTable = {
  'P0117': const DtcInfo(
    'P0117',
    'Engine coolant temperature sensor circuit — reading too low',
    HealthLevel.amber,
  ),
  'P0118': const DtcInfo(
    'P0118',
    'Engine coolant temperature sensor circuit — reading too high',
    HealthLevel.amber,
  ),
  'P0125': const DtcInfo(
    'P0125',
    'Insufficient coolant temperature for closed loop fuel control',
    HealthLevel.amber,
  ),
  'P0230': const DtcInfo(
    'P0230',
    'Fuel pump primary circuit malfunction',
    HealthLevel.red,
  ),
  'P0300': const DtcInfo(
    'P0300',
    'Random/multiple cylinder misfire detected',
    HealthLevel.red,
  ),
  'P0301': const DtcInfo(
    'P0301',
    'Cylinder 1 misfire detected',
    HealthLevel.red,
  ),
  'P0335': const DtcInfo(
    'P0335',
    'Crankshaft position sensor circuit malfunction',
    HealthLevel.red,
  ),
  'P0420': const DtcInfo(
    'P0420',
    'Catalyst system efficiency below threshold',
    HealthLevel.amber,
  ),
  'P0442': const DtcInfo(
    'P0442',
    'Evaporative emission system leak detected (small leak)',
    HealthLevel.amber,
  ),
  'P0500': const DtcInfo(
    'P0500',
    'Vehicle speed sensor malfunction',
    HealthLevel.amber,
  ),
  'P0562': const DtcInfo(
    'P0562',
    'System voltage low — check battery/charging system',
    HealthLevel.red,
  ),
  'P0605': const DtcInfo(
    'P0605',
    'Internal control module (ECU) memory checksum error',
    HealthLevel.red,
  ),
};

/// Looks up a DTC. Returns a generic "unknown code" info if not in the
/// table, so the UI always has something sensible to show.
DtcInfo lookupDtc(String code) {
  return dtcTable[code.toUpperCase()] ??
      DtcInfo(
        code,
        'Unrecognized diagnostic code — refer to dealer for manufacturer-specific lookup.',
        HealthLevel.amber,
      );
}
