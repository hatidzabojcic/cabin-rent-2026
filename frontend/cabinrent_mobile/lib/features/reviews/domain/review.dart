class Review {
  const Review({
    required this.id,
    required this.reservationId,
    required this.cabinId,
    required this.cabinName,
    required this.guestName,
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
    guestName: json['guestName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    isApproved: json['isApproved'] as bool,
    createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
  );

  final int id;
  final int reservationId;
  final int cabinId;
  final String cabinName;
  final String guestName;
  final int rating;
  final String? comment;
  final bool isApproved;
  final DateTime createdAtUtc;
}
