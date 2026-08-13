import '../../../models/app_notification.dart';

/// `GET /notifications` (unread first), `PATCH /notifications/{id}/read`.
/// The app polls this on launch/resume/a light foreground timer — no
/// device-token registration, per PLAN_frontend.md's Firebase-free design.
abstract class NotificationsRepository {
  Future<List<AppNotification>> list();

  Future<void> markRead(String id);
}
