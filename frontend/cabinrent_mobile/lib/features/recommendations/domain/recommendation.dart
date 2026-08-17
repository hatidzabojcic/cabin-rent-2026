import '../../cabins/domain/cabin_summary.dart';

class Recommendation {
  const Recommendation({
    required this.cabinId,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.maxGuests,
    required this.score,
    required this.reason,
    required this.isPersonalized,
    this.averageRating,
    this.coverImageUrl,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
    cabinId: json['cabinId'] as int,
    name: json['name'] as String,
    city: json['city'] as String,
    pricePerNight: (json['pricePerNight'] as num).toDouble(),
    maxGuests: json['maxGuests'] as int,
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    coverImageUrl: json['coverImageUrl'] as String?,
    score: (json['score'] as num).toDouble(),
    reason: json['reason'] as String,
    isPersonalized: json['isPersonalized'] as bool,
  );

  final int cabinId;
  final String name;
  final String city;
  final double pricePerNight;
  final int maxGuests;
  final double? averageRating;
  final String? coverImageUrl;
  final double score;
  final String reason;
  final bool isPersonalized;

  CabinSummary get cabin => CabinSummary(
    id: cabinId,
    name: name,
    city: city,
    pricePerNight: pricePerNight,
    maxGuests: maxGuests,
    averageRating: averageRating,
    coverImageUrl: coverImageUrl,
  );
}
