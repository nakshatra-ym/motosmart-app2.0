import '../../core/network/api_client.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../models/app_notification.dart';
import '../../models/json_utils.dart';

/// `GET /notifications` (unread first), `PATCH /notifications/{id}/read`.
class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<AppNotification>> list() async {
    // Unlike the other list endpoints this one returns an object, so the unread
    // count can ride along for the badge; the items are nested under `items`.
    final response = await _api.getObject('/notifications', query: {'limit': 100});
    return asMapList(response['items']).map(AppNotification.fromJson).toList();
  }

  @override
  Future<void> markRead(String id) {
    return _api.patchVoid('/notifications/$id/read');
  }
}
