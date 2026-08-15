import 'package:cabinrent_desktop/features/notifications/domain/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification parses unread state and related entity', () {
    final notification = AppNotification.fromJson({
      'id': 1,
      'type': 'ReservationCreated',
      'title': 'Nova rezervacija',
      'message': 'Primljena je nova rezervacija.',
      'relatedEntityType': 'Reservation',
      'relatedEntityId': 4,
      'isRead': false,
      'readAtUtc': null,
      'createdAtUtc': '2026-08-15T12:00:00Z',
    });
    expect(notification.isRead, isFalse);
    expect(notification.relatedEntityId, 4);
  });
}
