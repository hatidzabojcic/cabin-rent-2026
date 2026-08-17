class Reservation {
  const Reservation({
    required this.id,
    required this.confirmationCode,
    required this.cabinName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.status,
    this.paymentStatus,
  });
  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as int,
    confirmationCode: json['confirmationCode'] as String,
    cabinName: json['cabinName'] as String,
    checkIn: DateTime.parse(json['checkIn'] as String),
    checkOut: DateTime.parse(json['checkOut'] as String),
    adults: json['adults'] as int,
    children: json['children'] as int,
    totalPrice: (json['totalPrice'] as num).toDouble(),
    status: json['status'] as String,
    paymentStatus: json['paymentStatus'] as String?,
  );
  final int id, adults, children;
  final String confirmationCode, cabinName, status;
  final DateTime checkIn, checkOut;
  final double totalPrice;
  final String? paymentStatus;
  bool get canCancel => status == 'Pending' || status == 'Confirmed';
  bool get canReview => status == 'Completed';
}

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}.';
String reservationStatus(String status) =>
    const {
      'Pending': 'Na čekanju',
      'Confirmed': 'Potvrđena',
      'Completed': 'Završena',
      'Cancelled': 'Otkazana',
      'Rejected': 'Odbijena',
    }[status] ??
    status;
