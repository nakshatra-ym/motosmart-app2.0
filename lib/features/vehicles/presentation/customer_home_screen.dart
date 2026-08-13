import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/vehicle.dart';
import '../../public/data/public_providers.dart';
import '../data/vehicles_providers.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    final customer = ref.watch(authControllerProvider).valueOrNull?.customer;
    final bikeModels = ref.watch(publicModelsProvider).valueOrNull;

    String modelName(String bikeModelId) {
      if (bikeModels == null) return 'Your Yamaha';
      for (final b in bikeModels) {
        if (b.id == bikeModelId) return b.displayName;
      }
      return 'Your Yamaha';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(customer == null ? 'My bike' : 'Hi, ${customer.name.split(' ').first}'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myVehiclesProvider),
        child: AsyncValueWidget<List<Vehicle>>(
          value: vehiclesAsync,
          onRetry: () => ref.invalidate(myVehiclesProvider),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return const EmptyState(
                icon: Icons.two_wheeler_outlined,
                title: 'No vehicle linked yet',
                subtitle: 'Ask your dealer to link your Yamaha to your account.',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: vehicles
                  .map((v) => _VehicleCard(vehicle: v, modelName: modelName(v.bikeModelId)))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.modelName});

  final Vehicle vehicle;
  final String modelName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.yamahaBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.yamahaBlue.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Icon(Icons.two_wheeler, color: AppColors.yamahaBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(modelName, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.registrationNo,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicle.purchaseDate == null
                      ? 'Purchase date not on file'
                      : 'Purchased ${DateFormat('MMM yyyy').format(vehicle.purchaseDate!)}',
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  '${vehicle.odometerKm} km',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/customer/home/analytics/${vehicle.id}'),
                icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                label: const Text('View live health & analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
