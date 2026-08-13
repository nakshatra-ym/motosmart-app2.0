import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;

import '../../../core/config/env.dart';
import '../../../core/network/network_providers.dart';
import '../../../obd_feature/screens/customer_dashboard_screen.dart';
import '../../../obd_feature/services/ai_explanation_service.dart';

import '../../../obd_feature/state/dashboard_provider.dart';
import '../data/backend_ai_explanation_service.dart';
import '../data/idle_obd_service.dart';
import 'obd_ai_actions.dart';

/// Bridges `lib/obd_feature/` (a self-contained module built on the
/// `provider` package) into the rest of the app, which otherwise uses
/// Riverpod. Scoping `ChangeNotifierProvider` to just this route's subtree
/// means the two state-management approaches never need to interact —
/// [DashboardProvider] owns its own `MockObdService` stream and disposes it
/// when this screen is popped.
///
/// The feed is a real ELM327 over Bluetooth, connected from the dashboard's
/// Bluetooth icon (see [DashboardProvider.connectToDevice]). Until then nothing
/// is emitted — see [IdleObdService] — and the dashboard shows a connect prompt
/// rather than simulated numbers.
///
/// Everything this screen adds — the AI summary bar and the backend-backed fault
/// explanations — is composed from the outside via constructor injection, so the
/// OBD module itself (Bluetooth code included) is used exactly as shipped.
class VehicleAnalyticsScreen extends ConsumerWidget {
  const VehicleAnalyticsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return legacy_provider.ChangeNotifierProvider(
      create: (_) => DashboardProvider(
        // Emits nothing: readings come from the ELM327 over Bluetooth, and the
        // dashboard asks the rider to connect until then. No invented data.
        obdService: IdleObdService(),
        // Fault explanations go through our backend (Bedrock) unless the app is
        // running on mock data, in which case the module's own service keeps its
        // original behaviour.
        aiService: Env.useMockData
            ? AiExplanationService(apiKey: Env.anthropicApiKey)
            : BackendAiExplanationService(
                api: ref.read(apiClientProvider),
                vehicleId: vehicleId,
              ),
      ),
      // The AI actions bar is composed *around* the dashboard rather than added
      // inside it, so `lib/obd_feature/` stays untouched. The bar only reads
      // DashboardProvider's published readings.
      child: Column(
        children: [
          const Expanded(child: CustomerDashboardScreen()),
          ObdAiActions(vehicleId: vehicleId),
        ],
      ),
    );
  }
}
