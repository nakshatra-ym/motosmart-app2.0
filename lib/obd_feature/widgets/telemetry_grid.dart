import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../models/obd_reading.dart';

class TelemetryGrid extends StatelessWidget {
  final ObdReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _TelemetryItem('RPM', reading.rpm.toString(), Icons.speed),
      _TelemetryItem('Speed', '${reading.speedKph.toStringAsFixed(0)} km/h', Icons.directions_bike),
      _TelemetryItem(
        'Coolant',
        '${reading.coolantTempC.toStringAsFixed(1)}°C',
        Icons.thermostat,
      ),
      _TelemetryItem(
        'Battery',
        '${reading.batteryVoltage.toStringAsFixed(2)} V',
        Icons.battery_full,
      ),
      _TelemetryItem(
        'Throttle',
        '${reading.throttlePositionPct.toStringAsFixed(0)}%',
        Icons.tune,
      ),
      _TelemetryItem('Fuel', '${reading.fuelLevelPct.toStringAsFixed(0)}%', Icons.local_gas_station),
    ];

    return Column(
      children: [
        for (var i = 0; i < items.length; i += 2) ...[
          if (i > 0) Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(child: _metric(theme, items[i])),
                Container(
                  width: 1,
                  height: 44,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
                Expanded(
                  child: i + 1 < items.length
                      ? _metric(theme, items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metric(ThemeData theme, _TelemetryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: AppColors.yamahaBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
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
  final IconData icon;
  _TelemetryItem(this.label, this.value, this.icon);
}
