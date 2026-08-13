import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/service_record.dart';
import '../../vehicles/data/vehicles_providers.dart';

class ServiceHistoryScreen extends ConsumerWidget {
  const ServiceHistoryScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(serviceHistoryProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Service history')),
      body: AsyncValueWidget<List<ServiceRecord>>(
        value: historyAsync,
        onRetry: () => ref.invalidate(serviceHistoryProvider(vehicleId)),
        data: (records) {
          if (records.isEmpty) {
            return const EmptyState(icon: Icons.history, title: 'No service records yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.build_circle_outlined),
                  title: Text(r.serviceType),
                  subtitle: Text(
                    '${DateFormat('d MMM yyyy').format(r.serviceDate)} · ${r.odometerKm} km',
                  ),
                  trailing: Text(
                    r.cost == 0 ? 'Free' : '₹${r.cost.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
