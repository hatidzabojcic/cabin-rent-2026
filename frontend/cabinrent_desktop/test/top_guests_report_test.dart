import 'package:cabinrent_desktop/features/reports/domain/top_guests_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('top guests report parses ranking metrics', () {
    final report = TopGuestsReport.fromJson({
      'year': 2026,
      'cabinId': null,
      'guests': [
        {
          'guestId': 3,
          'guestName': 'Demo Guest',
          'email': 'guest@cabinrent.local',
          'phoneNumber': null,
          'reservations': 2,
          'completedStays': 1,
          'nights': 3,
          'cabinsVisited': 1,
          'totalSpent': 540.0,
        },
      ],
    });

    expect(report.guests.single.guestName, 'Demo Guest');
    expect(report.guests.single.nights, 3);
    expect(report.guests.single.totalSpent, 540);
  });
}
