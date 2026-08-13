import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_provider.dart';
import '../widgets/health_badge.dart';
import '../widgets/telemetry_grid.dart';
import '../widgets/alert_card.dart';
import 'obd_connect_screen.dart';

class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  void _openConnectScreen(BuildContext context) {
    // Re-provide the SAME DashboardProvider instance to the pushed route —
    // it lives above this screen in the tree only, so a plain
    // Navigator.push would land outside its scope without this.
    final dashboard = context.read<DashboardProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: dashboard,
          child: const ObdConnectScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final reading = dashboard.latestReading;
    final health = dashboard.health;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bike — Health'),
        actions: [
          IconButton(
            tooltip: dashboard.isLive ? 'Connected — ${dashboard.liveDeviceName}' : 'Connect OBD device',
            icon: Icon(dashboard.isLive ? Icons.bluetooth_connected : Icons.bluetooth),
            onPressed: () => _openConnectScreen(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: dashboard.isLive ? Colors.green.shade50 : Colors.orange.shade50,
              child: ListTile(
                dense: true,
                leading: Icon(
                  dashboard.isLive ? Icons.bluetooth_connected : Icons.science_outlined,
                  color: dashboard.isLive ? Colors.green : Colors.orange,
                ),
                title: Text(
                  dashboard.isLive
                      ? 'Live data — ${dashboard.liveDeviceName}'
                      : 'Simulated data — tap the Bluetooth icon to connect a real ELM327',
                ),
              ),
            ),
            const SizedBox(height: 16),
            HealthBadge(health: health),
            const SizedBox(height: 16),
            const Text('Live Telemetry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TelemetryGrid(reading: reading),
            if (reading.activeDtcCodes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Active Alerts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ...reading.activeDtcCodes.map((code) => AlertCard(
                    dtcCode: code,
                    aiExplanation: dashboard.aiExplanation,
                    aiLoading: dashboard.aiLoading,
                  )),
            ],
            const SizedBox(height: 20),
            // Demo-only controls — remove before shipping, keep for judging.
            _DemoControls(dashboard: dashboard),
          ],
        ),
      ),
    );
  }
}

/// Buttons to reliably trigger a fault on demand during a live demo,
/// instead of hoping the mock generator randomly produces one on stage.
class _DemoControls extends StatelessWidget {
  final DashboardProvider dashboard;
  const _DemoControls({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Demo controls',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => dashboard.injectFault(['P0300']),
                  child: const Text('Inject misfire (red)'),
                ),
                ElevatedButton(
                  onPressed: () => dashboard.injectFault(['P0117']),
                  child: const Text('Inject coolant fault (amber)'),
                ),
                OutlinedButton(
                  onPressed: () => dashboard.clearFault(),
                  child: const Text('Clear fault'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
