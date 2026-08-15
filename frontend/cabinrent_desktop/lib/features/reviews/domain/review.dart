class Review {
  const Review({
    required this.id,
    required this.reservationId,
    required this.cabinId,
    required this.cabinName,
    required this.guestId,
    required this.guestName,
    required this.guestEmail,
    required this.rating,
    required this.isApproved,
    required this.createdAtUtc,
    this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as int,
    reservationId: json['reservationId'] as int,
    cabinId: json['cabinId'] as int,
    cabinName: json['cabinName'] as String,
    guestId: json['guestId'] as int,
    guestName: json['guestName'] as String,
    guestEmail: json['guestEmail'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    isApproved: json['isApproved'] as bool,
    createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toLocal(),
  );

  final int id;
  final int reservationId;
  final int cabinId;
  final String cabinName;
  final int guestId;
  final String guestName;
  final String guestEmail;
  final int rating;
  final String? comment;
  final bool isApproved;
  final DateTime createdAtUtc;
}

String formatReviewDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}.';
