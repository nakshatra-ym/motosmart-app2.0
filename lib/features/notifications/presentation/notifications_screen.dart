import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/design.dart';
import '../../../core/config/theme.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/app_notification.dart';
import '../../../models/enums.dart';
import '../data/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.newLead => Icons.person_add_alt_1,
        NotificationType.testRide => Icons.two_wheeler,
        NotificationType.serviceReply => Icons.build_outlined,
        NotificationType.followupDue => Icons.event_available,
      };

  Future<void> _onTap(BuildContext context, WidgetRef ref, AppNotification n) async {
    if (!n.isRead) {
      await ref.read(notificationsRepositoryProvider).markRead(n.id);
      ref.invalidate(notificationsListProvider);
    }
    final leadId = n.payload['leadId'] as String?;
    if (leadId != null && context.mounted) {
      context.push('/dealer/leads/$leadId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsListProvider),
        child: AsyncValueWidget<List<AppNotification>>(
          value: notificationsAsync,
          onRetry: () => ref.invalidate(notificationsListProvider),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                subtitle: 'New leads, test-ride requests, and follow-up reminders show up here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: n.isRead
                        ? Colors.black.withValues(alpha: 0.05)
                        : AppColors.yamahaBlue.withValues(alpha: 0.1),
                    child: Icon(
                      _iconFor(n.type),
                      color: n.isRead ? Ds.inkMuted : AppColors.yamahaBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(n.body),
                  trailing: Text(
                    DateFormat('d MMM, h:mm a').format(n.createdAt),
                    style: const TextStyle(fontSize: 11, color: Ds.inkMuted),
                  ),
                  onTap: () => _onTap(context, ref, n),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
