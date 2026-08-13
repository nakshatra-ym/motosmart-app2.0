import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/enums.dart';
import '../../../models/service_request.dart';
import '../../../models/service_status.dart';
import '../../../models/vehicle.dart';
import '../../vehicles/data/vehicles_providers.dart';
import '../data/service_providers.dart';

class ServiceHomeScreen extends ConsumerWidget {
  const ServiceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    final requestsAsync = ref.watch(serviceRequestsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Service')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myVehiclesProvider);
          ref.invalidate(serviceRequestsListProvider);
        },
        child: AsyncValueWidget<List<Vehicle>>(
          value: vehiclesAsync,
          onRetry: () => ref.invalidate(myVehiclesProvider),
          data: (vehicles) {
            final primaryVehicle = vehicles.isEmpty ? null : vehicles.first;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (primaryVehicle != null) _ServiceStatusCard(vehicleId: primaryVehicle.id),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: primaryVehicle == null
                      ? null
                      : () => context.push('/customer/service/new', extra: primaryVehicle.id),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Raise a new service request'),
                ),
                if (primaryVehicle != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/customer/service/history/${primaryVehicle.id}'),
                    icon: const Icon(Icons.history),
                    label: const Text('View service history'),
                  ),
                ],
                const SizedBox(height: 24),
                Text('My requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                AsyncValueWidget<List<ServiceRequest>>(
                  value: requestsAsync,
                  onRetry: () => ref.invalidate(serviceRequestsListProvider),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: EmptyState(
                          icon: Icons.build_outlined,
                          title: 'No service requests yet',
                        ),
                      );
                    }
                    return Column(
                      children: requests.map((r) => _RequestTile(request: r)).toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceStatusCard extends ConsumerWidget {
  const _ServiceStatusCard({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(serviceStatusProvider(vehicleId));
    return AsyncValueWidget<ServiceStatus>(
      value: statusAsync,
      onRetry: () => ref.invalidate(serviceStatusProvider(vehicleId)),
      data: (status) {
        final color = status.isOverdue ? AppColors.hot : AppColors.statusClosedWon;
        return Card(
          color: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(status.isOverdue ? Icons.warning_amber : Icons.check_circle_outline, color: color),
                    const SizedBox(width: 8),
                    Text(
                      status.isOverdue ? 'Service overdue' : 'Service up to date',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (status.lastService != null)
                  Text(
                    'Last: ${DateFormat('d MMM yyyy').format(status.lastService!.serviceDate)} '
                    'at ${status.lastService!.odometerKm} km',
                    style: const TextStyle(fontSize: 13),
                  ),
                if (status.nextServiceDate != null || status.nextServiceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Next due: '
                      '${status.nextServiceDate != null ? DateFormat('d MMM yyyy').format(status.nextServiceDate!) : '—'}'
                      '${status.nextServiceKm != null ? ' or ${status.nextServiceKm} km' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final ServiceRequest request;

  Color get _color => switch (request.status) {
        ServiceRequestStatus.open => AppColors.statusNew,
        ServiceRequestStatus.inProgress => AppColors.statusFollowUp,
        ServiceRequestStatus.resolved => AppColors.statusClosedWon,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(request.type, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(request.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(request.status.label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        onTap: () => context.push('/customer/service/${request.id}'),
      ),
    );
  }
}
