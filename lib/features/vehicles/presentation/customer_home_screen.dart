import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/config/design.dart';
import '../../../core/widgets/document.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('REGISTERED OWNER', style: Ds.label()),
            Text(
              customer == null ? 'My bike' : customer.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
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
              padding: Ds.pagePad(context),
              children: [
                for (final v in vehicles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Ds.s4),
                    child: DocPage(
                      child: _VehicleCard(
                        vehicle: v,
                        modelName: modelName(v.bikeModelId),
                      ),
                    ),
                  ),
              ],
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
    final text = Theme.of(context).textTheme;

    // The owner's registration certificate: the model as the title, the plate as
    // the identity, and the two figures an owner is ever asked for.
    return Container(
      decoration: BoxDecoration(
        color: Ds.surfaceRaised,
        borderRadius: BorderRadius.circular(Ds.rMd),
        border: Border.all(color: Ds.lineStrong),
        boxShadow: Ds.lift(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The card's authority band, as the top of an RC is printed.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Ds.s4,
              vertical: Ds.s2 + 2,
            ),
            decoration: const BoxDecoration(
              color: Ds.brand,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Ds.rMd - 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CERTIFICATE OF REGISTRATION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Ds.label(color: Colors.white)
                        .copyWith(fontSize: 10, letterSpacing: 1.1),
                  ),
                ),
                const Icon(Icons.verified_outlined, size: 14, color: Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Ds.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MODEL', style: Ds.label()),
                          const SizedBox(height: 2),
                          Text(
                            modelName,
                            style: text.headlineSmall,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Ds.s3),
                    const Icon(Icons.two_wheeler, size: 30, color: Ds.lineStrong),
                  ],
                ),
                const SizedBox(height: Ds.s4),
                // The plate: the one piece of this card an owner recognises
                // instantly, so it is set as a plate.
                Align(
                  alignment: Alignment.centerLeft,
                  child: PlateMark(text: vehicle.registrationNo, size: 19),
                ),
                const SizedBox(height: Ds.s4),
                const PerforationLine(),
                const SizedBox(height: Ds.s3),
                Row(
                  children: [
                    Expanded(
                      child: DocField(
                        label: 'Odometer',
                        emphasis: true,
                        value: '${vehicle.odometerKm} km',
                      ),
                    ),
                    Expanded(
                      child: DocField(
                        label: 'Purchased',
                        value: vehicle.purchaseDate == null
                            ? 'Not on file'
                            : DateFormat('MMM yyyy').format(vehicle.purchaseDate!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Ds.s4),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/customer/home/analytics/${vehicle.id}'),
                  icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                  label: const Text('Live health & diagnostics'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
