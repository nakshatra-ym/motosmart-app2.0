import '../../features/notifications/data/notifications_repository.dart';
import '../../models/app_notification.dart';
import 'mock_data_store.dart';

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository(this._store, {required String? Function() currentEmployeeId})
      : _currentEmployeeId = currentEmployeeId;

  final MockDataStore _store;
  final String? Function() _currentEmployeeId;

  @override
  Future<List<AppNotification>> list() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final employeeId = _currentEmployeeId();
    if (employeeId == null) return const [];
    final list = _store.notifications.where((n) => n.recipientId == employeeId).toList()
      ..sort((a, b) {
        if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return list;
  }

  @override
  Future<void> markRead(String id) async {
    final index = _store.notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _store.notifications[index] = _store.notifications[index].copyWith(isRead: true);
  }
}
