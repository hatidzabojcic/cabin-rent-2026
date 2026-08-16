import 'package:cabinrent_mobile/features/auth/domain/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses authenticated guest session', () {
    final session = AuthSession.fromJson({
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'expiresAtUtc': '2026-08-17T12:00:00Z',
      'user': {
        'id': 3,
        'firstName': 'Demo',
        'lastName': 'Guest',
        'email': 'guest@cabinrent.local',
        'userName': 'guest',
        'phoneNumber': null,
        'isActive': true,
        'roles': ['Guest'],
      },
    });

    expect(session.user.fullName, 'Demo Guest');
    expect(session.user.isGuest, isTrue);
    expect(session.expiresAtUtc.isUtc, isTrue);
  });
}
