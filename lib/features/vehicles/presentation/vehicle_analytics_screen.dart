import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/env.dart';
import '../../../obd_feature/screens/customer_dashboard_screen.dart';
import '../../../obd_feature/services/ai_explanation_service.dart';
import '../../../obd_feature/services/mock_obd_service.dart';
import '../../../obd_feature/state/dashboard_provider.dart';

/// Bridges `lib/obd_feature/` (a self-contained module built on the
/// `provider` package) into the rest of the app, which otherwise uses
/// Riverpod. Scoping `ChangeNotifierProvider` to just this route's subtree
/// means the two state-management approaches never need to interact —
/// [DashboardProvider] owns its own `MockObdService` stream and disposes it
/// when this screen is popped.
///
/// Starts on simulated telemetry for one bike, rider's own perspective
/// only. The rider can swap to a real ELM327 (or an emulator standing in
/// for one) over Bluetooth at runtime via the dashboard's Bluetooth icon —
/// see [DashboardProvider.connectToDevice]. Nothing here changes either way.
class VehicleAnalyticsScreen extends StatelessWidget {
  const VehicleAnalyticsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return legacy_provider.ChangeNotifierProvider(
      create: (_) => DashboardProvider(
        obdService: MockObdService(),
        aiService: AiExplanationService(apiKey: Env.anthropicApiKey),
      ),
      child: const CustomerDashboardScreen(),
    );
  }
}
