import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/enums.dart';
import '../../../models/test_ride_booking.dart';
import '../../public/data/public_providers.dart';
import '../data/test_ride_providers.dart';

/// The "Test rides" segment of the Leads screen — a test-ride booking is
/// just another lead activity, so it's embedded here rather than living
/// behind its own bottom-nav tab.
class TestRidesTab extends ConsumerWidget {
  const TestRidesTab({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    TestRideBooking booking,
    TestRideStatus status,
  ) async {
    try {
      await ref.read(testRideRepositoryProvider).updateStatus(booking.id, status);
      ref.invalidate(testRidesListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(testRidesListProvider);
    final bikeModels = ref.watch(publicModelsProvider).valueOrNull;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(testRidesListProvider),
      child: AsyncValueWidget<List<TestRideBooking>>(
        value: bookingsAsync,
        onRetry: () => ref.invalidate(testRidesListProvider),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.two_wheeler_outlined,
              title: 'No test ride requests yet',
              subtitle: 'Bookings from the public site will show up here.',
            );
          }
          String? bikeName(String id) {
            if (bikeModels == null) return null;
            for (final b in bikeModels) {
              if (b.id == id) return b.displayName;
            }
            return null;
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          _StatusChip(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(booking.mobile, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 6),
                      Text(
                        bikeName(booking.bikeModelId) ?? 'Unknown model',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${DateFormat('d MMM yyyy').format(booking.preferredDate)} · ${booking.preferredTime}',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      if (booking.status == TestRideStatus.requested ||
                          booking.status == TestRideStatus.confirmed) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (booking.status == TestRideStatus.requested)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _updateStatus(
                                      context, ref, booking, TestRideStatus.confirmed),
                                  child: const Text('Confirm'),
                                ),
                              ),
                            if (booking.status == TestRideStatus.requested)
                              const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _updateStatus(
                                    context, ref, booking, TestRideStatus.completed),
                                child: const Text('Mark completed'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TestRideStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TestRideStatus.requested => AppColors.statusNew,
      TestRideStatus.confirmed => AppColors.statusFollowUp,
      TestRideStatus.completed => AppColors.statusClosedWon,
      TestRideStatus.cancelled => AppColors.statusClosedLost,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
