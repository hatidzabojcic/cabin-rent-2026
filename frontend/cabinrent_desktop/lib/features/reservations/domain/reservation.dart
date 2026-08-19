class Reservation {
  const Reservation({
    required this.id,
    required this.confirmationCode,
    required this.cabinId,
    required this.cabinName,
    required this.ownerId,
    required this.guestId,
    required this.guestName,
    required this.guestEmail,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.pricePerNight,
    required this.totalPrice,
    required this.status,
    required this.createdAtUtc,
    this.guestPhoneNumber,
    this.specialRequests,
    this.paymentStatus,
    this.statusChangedByUserId,
    this.statusChangedByUserName,
    this.statusChangedAtUtc,
    this.statusChangeReason,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as int,
    confirmationCode: json['confirmationCode'] as String,
    cabinId: json['cabinId'] as int,
    cabinName: json['cabinName'] as String,
    ownerId: json['ownerId'] as int,
    guestId: json['guestId'] as int,
    guestName: json['guestName'] as String,
    guestEmail: json['guestEmail'] as String,
    guestPhoneNumber: json['guestPhoneNumber'] as String?,
    checkIn: DateTime.parse(json['checkIn'] as String),
    checkOut: DateTime.parse(json['checkOut'] as String),
    adults: json['adults'] as int,
    children: json['children'] as int,
    pricePerNight: (json['pricePerNight'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
    status: json['status'] as String,
    specialRequests: json['specialRequests'] as String?,
    paymentStatus: json['paymentStatus'] as String?,
    statusChangedByUserId: json['statusChangedByUserId'] as int?,
    statusChangedByUserName: json['statusChangedByUserName'] as String?,
    statusChangedAtUtc: json['statusChangedAtUtc'] == null
        ? null
        : DateTime.parse(json['statusChangedAtUtc'] as String).toUtc(),
    statusChangeReason: json['statusChangeReason'] as String?,
    createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
  );

  final int id;
  final String confirmationCode;
  final int cabinId;
  final String cabinName;
  final int ownerId;
  final int guestId;
  final String guestName;
  final String guestEmail;
  final String? guestPhoneNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double pricePerNight;
  final double totalPrice;
  final String status;
  final String? specialRequests;
  final String? paymentStatus;
  final int? statusChangedByUserId;
  final String? statusChangedByUserName;
  final DateTime? statusChangedAtUtc;
  final String? statusChangeReason;
  final DateTime createdAtUtc;

  int get nights => checkOut.difference(checkIn).inDays;
  int get guestCount => adults + children;

  List<String> get allowedNextStatuses => switch (status) {
    'Pending' => const ['Confirmed', 'Rejected', 'Cancelled'],
    'Confirmed' => const ['Completed', 'Cancelled'],
    _ => const [],
  };
}

abstract final class ReservationLabels {
  static const statuses = <String, String>{
    'Pending': 'Na čekanju',
    'Confirmed': 'Potvrđena',
    'Completed': 'Završena',
    'Cancelled': 'Otkazana',
    'Rejected': 'Odbijena',
  };

  static const payments = <String, String>{
    'Pending': 'Na čekanju',
    'Paid': 'Plaćeno',
    'Failed': 'Neuspjelo',
    'Refunded': 'Refundirano',
  };

  static String status(String value) => statuses[value] ?? value;
  static String payment(String? value) =>
      value == null ? 'Nije evidentirano' : payments[value] ?? value;
}

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';
