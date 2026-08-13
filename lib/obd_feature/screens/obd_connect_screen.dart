import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_provider.dart';

/// Lets the rider pick an already-paired Bluetooth device (a real ELM327,
/// or a phone/app emulating one) to swap the dashboard from simulated to
/// live telemetry. Pairing itself happens in the OS Bluetooth settings —
/// this screen only lists bonded devices and connects to one.
class ObdConnectScreen extends StatefulWidget {
  const ObdConnectScreen({super.key});

  @override
  State<ObdConnectScreen> createState() => _ObdConnectScreenState();
}

class _ObdConnectScreenState extends State<ObdConnectScreen> {
  List<BluetoothDevice>? _devices;
  String? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final dashboard = context.read<DashboardProvider>();
      final supported = await dashboard.isBluetoothAvailable;
      if (!supported) {
        setState(() {
          _loading = false;
          _loadError = 'Bluetooth is not supported on this device.';
        });
        return;
      }
      final devices = await dashboard.pairedDevices;
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not read paired devices: $e';
      });
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    final dashboard = context.read<DashboardProvider>();
    await dashboard.connectToDevice(device);
    if (!mounted) return;
    if (dashboard.connectionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dashboard.connectionError!)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect OBD device'),
        actions: [
          IconButton(onPressed: _loadDevices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          if (dashboard.isLive)
            Card(
              margin: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.bluetooth_connected, color: Colors.green),
                title: Text('Connected — ${dashboard.liveDeviceName}'),
                trailing: TextButton(
                  onPressed: () => dashboard.disconnectDevice(),
                  child: const Text('Disconnect'),
                ),
              ),
            ),
          Expanded(child: _buildBody(dashboard)),
        ],
      ),
    );
  }

  Widget _buildBody(DashboardProvider dashboard) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_loadError!, textAlign: TextAlign.center),
        ),
      );
    }
    final devices = _devices ?? const [];
    if (devices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No paired devices found. Pair your ELM327 (or the phone '
            "emulating one) in this phone's Bluetooth settings first, "
            'then come back and hit refresh.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text((device.name?.isNotEmpty ?? false) ? device.name! : device.address),
          subtitle: Text(device.address),
          trailing: dashboard.isConnecting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.chevron_right),
          onTap: dashboard.isConnecting ? null : () => _connect(device),
        );
      },
    );
  }
}
