import '../../../core/config/app_config.dart';

class CabinSummary {
  const CabinSummary({
    required this.id,
    required this.name,
    required this.city,
    required this.pricePerNight,
    required this.maxGuests,
    this.averageRating,
    this.coverImageUrl,
  });
  factory CabinSummary.fromJson(Map<String, dynamic> json) => CabinSummary(
    id: json['id'] as int,
    name: json['name'] as String,
    city: json['city'] as String,
    pricePerNight: (json['pricePerNight'] as num).toDouble(),
    maxGuests: json['maxGuests'] as int,
    averageRating: (json['averageRating'] as num?)?.toDouble(),
    coverImageUrl: json['coverImageUrl'] as String?,
  );
  final int id, maxGuests;
  final String name, city;
  final double pricePerNight;
  final double? averageRating;
  final String? coverImageUrl;
  String? get resolvedImageUrl {
    final value = coverImageUrl;
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    return '${AppConfig.apiBaseUrl}${value.startsWith('/') ? '' : '/'}$value';
  }
}
