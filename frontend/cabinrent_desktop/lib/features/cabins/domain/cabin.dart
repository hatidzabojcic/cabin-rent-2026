class Cabin {
  const Cabin({
    required this.id,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.maxGuests,
    this.averageRating,
    this.coverImageUrl,
  });

  factory Cabin.fromJson(Map<String, dynamic> json) => Cabin(
    id: json['id'] as int,
    name: json['name'] as String,
    city: json['city'] as String,
    pricePerNight: (json['pricePerNight'] as num).toDouble(),
    maxGuests: json['maxGuests'] as int,
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    coverImageUrl: json['coverImageUrl'] as String?,
  );

  final int id;
  final String name;
  final String city;
  final double pricePerNight;
  final int maxGuests;
  final double? averageRating;
  final String? coverImageUrl;
}
