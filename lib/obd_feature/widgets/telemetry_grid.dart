import 'package:flutter/material.dart';

import '../../core/config/design.dart';
import '../models/obd_reading.dart';

/// The live readings, set as an inspection sheet's measurement block.
///
/// Figures dominate and labels sit under them in the pre-printed register, so a
/// rider reads six numbers at a glance. The values are tabular, which is what
/// keeps them from jittering sideways as the stream updates — a genuine problem
/// with proportional digits on a feed that ticks every 800ms.
class TelemetryGrid extends StatelessWidget {
  final ObdReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final items = <_TelemetryItem>[
      _TelemetryItem('Engine', reading.rpm.toString(), 'rpm', Icons.speed),
      _TelemetryItem('Speed', reading.speedKph.toStringAsFixed(0), 'km/h',
          Icons.directions_bike),
      _TelemetryItem('Coolant', reading.coolantTempC.toStringAsFixed(0), '°C',
          Icons.thermostat,
          // The two readings that mean something is wrong get to say so.
          alert: reading.coolantTempC >= 105),
      _TelemetryItem('Battery', reading.batteryVoltage.toStringAsFixed(2), 'V',
          Icons.battery_charging_full,
          alert: reading.batteryVoltage < 12.0 || reading.batteryVoltage > 15.0),
      _TelemetryItem('Throttle', reading.throttlePositionPct.toStringAsFixed(0),
          '%', Icons.tune),
      _TelemetryItem('Fuel', reading.fuelLevelPct.toStringAsFixed(0), '%',
          Icons.local_gas_station,
          alert: reading.fuelLevelPct < 10),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across on a phone, six across on a tablet — one row of
        // instruments rather than a grid that goes square and wastes the width.
        final columns = constraints.maxWidth >= 620 ? 6 : 3;
        const gap = Ds.s2;
        final cellWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(width: cellWidth, child: _Instrument(item: item)),
          ],
        );
      },
    );
  }
}

class _Instrument extends StatelessWidget {
  const _Instrument({required this.item});

  final _TelemetryItem item;

  @override
  Widget build(BuildContext context) {
    final accent = item.alert ? Ds.alert : Ds.ink;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Ds.s2 + 2,
        vertical: Ds.s3,
      ),
      decoration: BoxDecoration(
        color: item.alert ? Ds.alert.withValues(alpha: 0.05) : Ds.surfaceRaised,
        borderRadius: BorderRadius.circular(Ds.rMd),
        border: Border.all(
          color: item.alert ? Ds.alert.withValues(alpha: 0.4) : Ds.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 13, color: item.alert ? Ds.alert : Ds.inkMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ds.label(
                    color: item.alert ? Ds.alert : Ds.inkMuted,
                  ).copyWith(fontSize: 9.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: Ds.s2),
          // Value and unit on one baseline, scaled down rather than wrapped, so
          // a four-digit rpm never overflows its cell.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(item.value, style: Ds.figure(21, weight: 720, color: accent)),
                const SizedBox(width: 2),
                Text(
                  item.unit,
                  style: Ds.figure(10.5, weight: 600, color: Ds.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryItem {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  /// Outside the normal band for this reading.
  final bool alert;

  _TelemetryItem(this.label, this.value, this.unit, this.icon,
      {this.alert = false});
}
