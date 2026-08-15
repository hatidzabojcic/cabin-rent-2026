import '../../../core/api/api_client.dart';
import '../domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> getNotifications({bool? isRead}) async {
    final query = isRead == null ? '' : '?isRead=$isRead';
    return (await _api.getList('/api/notifications$query', authenticated: true))
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async =>
      (await _api.getObject(
            '/api/notifications/summary',
            authenticated: true,
          ))['unreadCount']
          as int;

  Future<void> markRead(int id) => _api.patch(
    '/api/notifications/$id/read',
    body: const <String, dynamic>{},
    authenticated: true,
  );

  Future<void> markAllRead() async {
    await _api.patch(
      '/api/notifications/read-all',
      body: const <String, dynamic>{},
      authenticated: true,
    );
  }
}
