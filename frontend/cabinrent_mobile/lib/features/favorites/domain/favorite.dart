class Favorite {
  const Favorite({
    required this.cabinId,
    required this.cabinName,
    required this.pricePerNight,
    required this.createdAtUtc,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    cabinId: json['cabinId'] as int,
    cabinName: json['cabinName'] as String,
    pricePerNight: (json['pricePerNight'] as num).toDouble(),
    createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
  );

  final int cabinId;
  final String cabinName;
  final double pricePerNight;
  final DateTime createdAtUtc;
}
