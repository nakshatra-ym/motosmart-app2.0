import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/app_visuals.dart';
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
    final theme = Theme.of(context);

    String modelName(String bikeModelId) {
      if (bikeModels == null) return 'Your Yamaha';
      for (final b in bikeModels) {
        if (b.id == bikeModelId) return b.displayName;
      }
      return 'Your Yamaha';
    }

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer == null ? 'My bike' : 'Hi, ${customer.name.split(' ').first}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Your garage',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.yamahaBlue,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: vehicles
                    .map((v) => _VehicleCard(vehicle: v, modelName: modelName(v.bikeModelId)))
                    .toList(),
              );
            },
          ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIconWell(
                  icon: Icons.two_wheeler_rounded,
                  size: 54,
                  iconSize: 26,
                  filled: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(modelName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        vehicle.registrationNo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vehicle.purchaseDate == null
                        ? 'Purchase date not on file'
                        : 'Purchased ${DateFormat('MMM yyyy').format(vehicle.purchaseDate!)}',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
                  ),
                  Text(
                    '${vehicle.odometerKm} km',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.yamahaBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/customer/home/analytics/${vehicle.id}'),
                icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                label: const Text('Live health & analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
