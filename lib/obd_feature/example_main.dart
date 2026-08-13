// EXAMPLE ENTRY POINT — merge the relevant bits into your existing
// main.dart / app router rather than replacing it wholesale, unless
// you're starting a fresh project just for this feature demo.
//
// Scope: ONE bike, rider's own perspective, simulation data only.
// No dataset, no CSV, no fleet/dealer view here.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/mock_obd_service.dart';
import 'services/ai_explanation_service.dart';
import 'state/dashboard_provider.dart';
import 'screens/customer_dashboard_screen.dart';

void main() {
  runApp(const ObdDemoApp());
}

class ObdDemoApp extends StatelessWidget {
  const ObdDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(
        // Simulated data for one bike. Swap for a real BLE/BT ELM327
        // parser later — nothing downstream needs to change since it
        // only depends on Stream<ObdReading>.
        obdService: MockObdService(),
        aiService: AiExplanationService(
          // Put your Anthropic API key here for the demo, or read it
          // from a secure env/config source. Never hardcode a real
          // key in committed code beyond hackathon scope.
          apiKey: 'YOUR_ANTHROPIC_API_KEY',
        ),
      ),
      child: MaterialApp(
        title: 'Yamaha OBD Dashboard',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1565C0),
        ),
        home: const CustomerDashboardScreen(),
      ),
    );
  }
}
