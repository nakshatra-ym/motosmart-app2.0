import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../data/api/api_notifications_repository.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../data/mock/mock_notifications_repository.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../models/app_notification.dart';
import 'notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  if (ref.watch(useMockDataProvider)) {
    return MockNotificationsRepository(
      ref.watch(mockDataStoreProvider),
      currentEmployeeId: () => ref.read(authControllerProvider).valueOrNull?.employee?.id,
    );
  }
  return ApiNotificationsRepository(ref.watch(apiClientProvider));
});

/// Firebase-free "push": [DealerShell] invalidates this on a light
/// foreground timer and on app resume; screens invalidate it manually after
/// pull-to-refresh or any action that creates a notification (test-ride
/// booking, etc.). Deliberately not a `Stream.periodic` provider — that
/// leaves a real `Timer` running that outlives disposal in tests.
final notificationsListProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).list();
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsListProvider).valueOrNull ?? const [];
  return notifications.where((n) => !n.isRead).length;
});
