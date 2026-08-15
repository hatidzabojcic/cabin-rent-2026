import 'package:cabinrent_desktop/features/users/domain/managed_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('managed owner parses statistics and role labels', () {
    final user = ManagedUser.fromJson({
      'id': 2,
      'firstName': 'Demo',
      'lastName': 'Owner',
      'email': 'owner@cabinrent.local',
      'userName': 'owner',
      'phoneNumber': null,
      'isActive': true,
      'roles': ['Owner'],
      'cabinCount': 4,
      'reservationCount': 4,
    });

    expect(user.fullName, 'Demo Owner');
    expect(user.isOwner, isTrue);
    expect(user.cabinCount, 4);
    expect(roleLabel(user.roles.single), 'Vlasnik');
  });
}
