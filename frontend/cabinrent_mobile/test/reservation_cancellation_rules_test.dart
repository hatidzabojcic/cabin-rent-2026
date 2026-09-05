import 'package:cabinrent_mobile/features/reservations/domain/reservation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Reservation reservation({required String status, required DateTime checkIn}) {
    return Reservation(
      id: 1,
      confirmationCode: 'CR-TEST-001',
      cabinId: 1,
      cabinName: 'Test vikendica',
      checkIn: checkIn,
      checkOut: checkIn.add(const Duration(days: 2)),
      adults: 2,
      children: 0,
      pricePerNight: 100,
      totalPrice: 200,
      status: status,
      paidAmount: 0,
    );
  }

  test('future pending or confirmed reservation can be cancelled', () {
    expect(
      reservation(status: 'Pending', checkIn: DateTime(2099, 1, 1)).canCancel,
      isTrue,
    );
    expect(
      reservation(status: 'Confirmed', checkIn: DateTime(2099, 1, 1)).canCancel,
      isTrue,
    );
  });

  test('reservation cannot be cancelled on or after check-in', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    expect(reservation(status: 'Pending', checkIn: today).canCancel, isFalse);
    expect(
      reservation(status: 'Confirmed', checkIn: DateTime(2020, 1, 1)).canCancel,
      isFalse,
    );
  });

  test('other statuses cannot be cancelled even before check-in', () {
    expect(
      reservation(status: 'Completed', checkIn: DateTime(2099, 1, 1)).canCancel,
      isFalse,
    );
  });
}
