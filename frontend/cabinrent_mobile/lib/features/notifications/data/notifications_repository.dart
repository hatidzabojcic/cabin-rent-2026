import '../../../core/api/api_client.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> getNotifications() async =>
      (await _api.getList('/api/notifications', authenticated: true))
          .map(
            (value) => AppNotification.fromJson(value as Map<String, dynamic>),
          )
          .toList();

  Future<int> getUnreadCount() async =>
      (await _api.getObject(
            '/api/notifications/summary',
            authenticated: true,
          ))['unreadCount']
          as int;

  Future<void> markRead(int id) async {
    await _api.patch('/api/notifications/$id/read', authenticated: true);
  }

  Future<void> markAllRead() async {
    await _api.patch('/api/notifications/read-all', authenticated: true);
  }
}
