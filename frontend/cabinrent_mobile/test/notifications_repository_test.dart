import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/features/notifications/data/notifications_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads and marks guest notifications as read', () async {
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      expect(request.headers['Authorization'], 'Bearer guest-token');
      if (request.url.path.endsWith('/summary')) {
        return http.Response(jsonEncode({'unreadCount': 1}), 200);
      }
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode([
            {
              'id': 7,
              'type': 'ReservationStatusChanged',
              'title': 'Promijenjen status rezervacije',
              'message': 'Rezervacija je potvrđena.',
              'relatedEntityType': 'Reservation',
              'relatedEntityId': 12,
              'isRead': false,
              'readAtUtc': null,
              'createdAtUtc': '2026-08-17T10:00:00Z',
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path.endsWith('/read-all')) {
        return http.Response(jsonEncode({'unreadCount': 0}), 200);
      }
      return http.Response('', 204);
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';
    final repository = NotificationsRepository(api);

    final notifications = await repository.getNotifications();
    final unreadCount = await repository.getUnreadCount();
    await repository.markRead(notifications.single.id);
    await repository.markAllRead();

    expect(notifications.single.isRead, isFalse);
    expect(notifications.single.relatedEntityId, 12);
    expect(unreadCount, 1);
    expect(requests, [
      'GET /api/notifications',
      'GET /api/notifications/summary',
      'PATCH /api/notifications/7/read',
      'PATCH /api/notifications/read-all',
    ]);
  });
}
