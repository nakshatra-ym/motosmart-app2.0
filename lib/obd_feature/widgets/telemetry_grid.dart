import 'package:flutter/material.dart';
import '../models/obd_reading.dart';

class TelemetryGrid extends StatelessWidget {
  final ObdReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final items = [
      _TelemetryItem('RPM', reading.rpm.toString(), Icons.speed),
      _TelemetryItem('Speed', '${reading.speedKph.toStringAsFixed(0)} km/h',
          Icons.directions_bike),
      _TelemetryItem('Coolant',
          '${reading.coolantTempC.toStringAsFixed(1)}°C', Icons.thermostat),
      _TelemetryItem('Battery',
          '${reading.batteryVoltage.toStringAsFixed(2)} V', Icons.battery_full),
      _TelemetryItem('Throttle',
          '${reading.throttlePositionPct.toStringAsFixed(0)}%', Icons.tune),
      _TelemetryItem('Fuel', '${reading.fuelLevelPct.toStringAsFixed(0)}%',
          Icons.local_gas_station),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: items.map((i) => _card(i)).toList(),
    );
  }

  Widget _card(_TelemetryItem item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: Colors.grey.shade700),
          const SizedBox(height: 6),
          Text(item.value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(item.label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
