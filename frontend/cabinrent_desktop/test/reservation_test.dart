import 'package:cabinrent_desktop/features/reservations/domain/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending reservation exposes supported next statuses', () {
    final reservation = Reservation.fromJson({
      'id': 1,
      'confirmationCode': 'CR-TEST',
      'cabinId': 2,
      'cabinName': 'Test cabin',
      'ownerId': 3,
      'guestId': 4,
      'guestName': 'Test Guest',
      'guestEmail': 'guest@example.com',
      'guestPhoneNumber': null,
      'checkIn': '2026-09-01',
      'checkOut': '2026-09-04',
      'adults': 2,
      'children': 1,
      'pricePerNight': 100,
      'totalPrice': 300,
      'status': 'Pending',
      'specialRequests': null,
      'paymentStatus': 'Pending',
      'createdAtUtc': '2026-08-15T10:00:00Z',
    });

    expect(reservation.nights, 3);
    expect(reservation.guestCount, 3);
    expect(reservation.allowedNextStatuses, [
      'Confirmed',
      'Rejected',
      'Cancelled',
    ]);
  });
}
