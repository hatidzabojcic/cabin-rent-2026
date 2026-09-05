import 'package:cabinrent_mobile/features/reservations/domain/reservation.dart';
import 'package:cabinrent_mobile/features/reservations/presentation/reservation_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Reservation reservation(int id, String status, DateTime checkIn) =>
      Reservation(
        id: id,
        confirmationCode: 'CR-$id',
        cabinId: id,
        cabinName: 'Vikendica $id',
        checkIn: checkIn,
        checkOut: checkIn.add(const Duration(days: 2)),
        adults: 2,
        children: 0,
        pricePerNight: 100,
        totalPrice: 200,
        status: status,
        paidAmount: 0,
      );

  test('filters reservations by status and groups equal check-in days', () {
    final groups = groupReservationsByCheckIn(
      [
        reservation(1, 'Confirmed', DateTime(2026, 9, 10)),
        reservation(2, 'Pending', DateTime(2026, 9, 10, 15)),
        reservation(3, 'Confirmed', DateTime(2026, 9, 12)),
      ],
      status: 'Confirmed',
      now: DateTime(2026, 9, 5),
    );

    expect(groups, hasLength(2));
    expect(groups.first.date, DateTime(2026, 9, 10));
    expect(groups.first.reservations.map((item) => item.id), [1]);
    expect(groups.last.reservations.map((item) => item.id), [3]);
  });

  test('shows nearest upcoming days first and past days afterwards', () {
    final groups = groupReservationsByCheckIn([
      reservation(1, 'Completed', DateTime(2026, 8, 1)),
      reservation(2, 'Confirmed', DateTime(2026, 9, 20)),
      reservation(3, 'Confirmed', DateTime(2026, 9, 10)),
      reservation(4, 'Completed', DateTime(2026, 8, 20)),
    ], now: DateTime(2026, 9, 5));

    expect(groups.map((group) => group.date), [
      DateTime(2026, 9, 10),
      DateTime(2026, 9, 20),
      DateTime(2026, 8, 20),
      DateTime(2026, 8, 1),
    ]);
  });

  test('creates a localized day heading', () {
    expect(reservationDayLabel(DateTime(2026, 9, 10)), 'Četvrtak, 10.09.2026.');
  });
}
