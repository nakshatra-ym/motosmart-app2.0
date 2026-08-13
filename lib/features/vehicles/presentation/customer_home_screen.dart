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
    final name = customer?.name.split(' ').first ?? 'Rider';

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
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.yamahaBlue,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(myVehiclesProvider),
            child: AsyncValueWidget<List<Vehicle>>(
              value: vehiclesAsync,
              onRetry: () => ref.invalidate(myVehiclesProvider),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const EmptyState(
                    icon: Icons.two_wheeler_outlined,
                    title: 'Garage empty',
                    subtitle: 'Ask your dealer to link your Yamaha — then the magic starts.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    FadeSlideIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'YOUR GARAGE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.yamahaBlue,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const FloatingOrb(color: AppColors.magenta, size: 8),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hi, $name',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Health, service, and RideMate — one dark cockpit.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...vehicles.asMap().entries.map((entry) {
                      final v = entry.value;
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 80 + entry.key * 60),
                        child: _VehicleBento(
                          vehicle: v,
                          modelName: modelName(v.bikeModelId),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleBento extends StatelessWidget {
  const _VehicleBento({required this.vehicle, required this.modelName});

  final Vehicle vehicle;
  final String modelName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassPanel(
        style: GlassStyle.framed,
        glow: AppColors.yamahaBlue,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIconWell(
                  icon: Icons.two_wheeler_rounded,
                  size: 56,
                  iconSize: 26,
                  filled: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modelName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.registrationNo,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.inkMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    label: 'Purchased',
                    value: vehicle.purchaseDate == null
                        ? '—'
                        : DateFormat('MMM yyyy').format(vehicle.purchaseDate!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoChip(
                    label: 'Odometer',
                    value: '${vehicle.odometerKm} km',
                    accent: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/customer/home/analytics/${vehicle.id}'),
                icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                label: const Text('Open live health'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: accent ? AppColors.accent : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
