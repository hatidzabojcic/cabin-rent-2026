import '../domain/reservation.dart';

class ReservationDayGroup {
  const ReservationDayGroup({required this.date, required this.reservations});

  final DateTime date;
  final List<Reservation> reservations;
}

List<ReservationDayGroup> groupReservationsByCheckIn(
  Iterable<Reservation> reservations, {
  String? status,
  DateTime? now,
}) {
  final byDay = <DateTime, List<Reservation>>{};
  for (final reservation in reservations) {
    if (status != null && reservation.status != status) continue;
    final day = DateTime(
      reservation.checkIn.year,
      reservation.checkIn.month,
      reservation.checkIn.day,
    );
    byDay.putIfAbsent(day, () => []).add(reservation);
  }

  final todayValue = now ?? DateTime.now();
  final today = DateTime(todayValue.year, todayValue.month, todayValue.day);
  final dates = byDay.keys.toList()
    ..sort((first, second) {
      final firstIsUpcoming = !first.isBefore(today);
      final secondIsUpcoming = !second.isBefore(today);
      if (firstIsUpcoming != secondIsUpcoming) return firstIsUpcoming ? -1 : 1;
      return firstIsUpcoming
          ? first.compareTo(second)
          : second.compareTo(first);
    });

  return dates
      .map(
        (date) => ReservationDayGroup(
          date: date,
          reservations: byDay[date]!
            ..sort(
              (first, second) => first.cabinName.compareTo(second.cabinName),
            ),
        ),
      )
      .toList();
}

String reservationDayLabel(DateTime date) {
  const weekdays = [
    'Ponedjeljak',
    'Utorak',
    'Srijeda',
    'Četvrtak',
    'Petak',
    'Subota',
    'Nedjelja',
  ];
  return '${weekdays[date.weekday - 1]}, ${formatDate(date)}';
}
