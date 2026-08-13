import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/theme.dart';
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

    // Readings come from the bike, never from a generator. Until an ELM327 is
    // connected there is nothing honest to show, so the screen asks for the
    // device instead of displaying zeroes or invented values.
    final hasReadings = dashboard.isLive;

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
      body: hasReadings
          ? RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
                      title: Text('Live data — ${dashboard.liveDeviceName}'),
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
                ],
              ),
            )
          : _ConnectPrompt(
              isConnecting: dashboard.isConnecting,
              error: dashboard.connectionError,
              onConnect: () => _openConnectScreen(context),
            ),
    );
  }
}

/// Shown until a real device is feeding readings.
class _ConnectPrompt extends StatelessWidget {
  const _ConnectPrompt({
    required this.isConnecting,
    required this.error,
    required this.onConnect,
  });

  final bool isConnecting;
  final String? error;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: Colors.blueGrey.shade300),
            const SizedBox(height: 20),
            const Text(
              'Connect your OBD device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Live readings come from the ELM327 plugged into your bike. '
              'Pair the device over Bluetooth to see engine speed, coolant '
              'temperature, battery voltage and any fault codes.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isConnecting ? null : onConnect,
              icon: isConnecting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bluetooth),
              label: Text(isConnecting ? 'Connecting…' : 'Connect device'),
            ),
          ],
        ),
      ),
    );
  }
}
