import 'package:cabinrent_desktop/features/reviews/domain/review.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review parses management data', () {
    final review = Review.fromJson({
      'id': 1,
      'reservationId': 4,
      'cabinId': 1,
      'cabinName': 'Jahorinska idila',
      'guestId': 3,
      'guestName': 'Demo Guest',
      'guestEmail': 'guest@cabinrent.local',
      'rating': 5,
      'comment': 'Odličan boravak.',
      'isApproved': true,
      'createdAtUtc': '2026-08-10T12:00:00Z',
    });

    expect(review.rating, 5);
    expect(review.isApproved, isTrue);
    expect(review.cabinName, 'Jahorinska idila');
  });
}
