import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../models/obd_reading.dart';

class TelemetryGrid extends StatelessWidget {
  final ObdReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 360 ? 2 : 3;

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

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: crossAxisCount == 2 ? 1.35 : 1.1,
      children: items.map((i) => _card(context, i)).toList(),
    );
  }

  Widget _card(BuildContext context, _TelemetryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 18, color: AppColors.yamahaBlue),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
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
