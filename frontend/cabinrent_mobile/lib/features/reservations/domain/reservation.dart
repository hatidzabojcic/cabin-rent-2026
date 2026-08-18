class Reservation {
  const Reservation({
    required this.id,
    required this.confirmationCode,
    required this.cabinId,
    required this.cabinName,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.pricePerNight,
    required this.totalPrice,
    required this.status,
    required this.paidAmount,
    this.paymentStatus,
    this.paymentCurrency,
    this.paidAtUtc,
    this.specialRequests,
  });
  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as int,
    confirmationCode: json['confirmationCode'] as String,
    cabinId: json['cabinId'] as int? ?? 0,
    cabinName: json['cabinName'] as String,
    checkIn: DateTime.parse(json['checkIn'] as String),
    checkOut: DateTime.parse(json['checkOut'] as String),
    adults: json['adults'] as int,
    children: json['children'] as int,
    pricePerNight:
        (json['pricePerNight'] as num?)?.toDouble() ??
        (json['totalPrice'] as num).toDouble() /
            DateTime.parse(
              json['checkOut'] as String,
            ).difference(DateTime.parse(json['checkIn'] as String)).inDays,
    totalPrice: (json['totalPrice'] as num).toDouble(),
    status: json['status'] as String,
    paymentStatus: json['paymentStatus'] as String?,
    paidAmount:
        (json['paidAmount'] as num?)?.toDouble() ??
        (json['paymentStatus'] == 'Paid'
            ? (json['totalPrice'] as num).toDouble()
            : 0),
    paymentCurrency: json['paymentCurrency'] as String?,
    paidAtUtc: json['paidAtUtc'] == null
        ? null
        : DateTime.parse(json['paidAtUtc'] as String).toUtc(),
    specialRequests: json['specialRequests'] as String?,
  );
  final int id, adults, children;
  final int cabinId;
  final String confirmationCode, cabinName, status;
  final DateTime checkIn, checkOut;
  final double pricePerNight, totalPrice, paidAmount;
  final String? paymentStatus;
  final String? paymentCurrency, specialRequests;
  final DateTime? paidAtUtc;
  bool get canCancel => status == 'Pending' || status == 'Confirmed';
  bool get canReview => status == 'Completed';
  bool get canPay =>
      status == 'Confirmed' &&
      paymentStatus != 'Paid' &&
      paymentStatus != 'Refunded' &&
      checkOut.isAfter(DateTime.now());
  bool get canReschedule {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (status == 'Pending' || status == 'Confirmed') &&
        checkIn.isAfter(today) &&
        paymentStatus != 'Paid';
  }

  int get nights => checkOut.difference(checkIn).inDays;
  double get remainingAmount => (totalPrice - paidAmount).clamp(0, totalPrice);
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

String paymentStatusLabel(String? status) =>
    const {
      'Pending': 'Čeka plaćanje',
      'Paid': 'Plaćeno',
      'Failed': 'Neuspjelo',
      'Refunded': 'Refundirano',
    }[status] ??
    'Nije evidentirano';
