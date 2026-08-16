import '../../../core/config/app_config.dart';

class CabinDetails {
  const CabinDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.areaSquareMeters,
    required this.pricePerNight,
    required this.maxAdults,
    required this.maxChildren,
    required this.bedrooms,
    required this.bathrooms,
    required this.ownerName,
    required this.city,
    required this.cabinType,
    required this.images,
    required this.amenities,
  });

  factory CabinDetails.fromJson(Map<String, dynamic> json) => CabinDetails(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String,
    address: json['address'] as String,
    areaSquareMeters: (json['areaSquareMeters'] as num).toDouble(),
    pricePerNight: (json['pricePerNight'] as num).toDouble(),
    maxAdults: json['maxAdults'] as int,
    maxChildren: json['maxChildren'] as int,
    bedrooms: json['bedrooms'] as int,
    bathrooms: json['bathrooms'] as int,
    ownerName: json['ownerName'] as String,
    city: json['city'] as String,
    cabinType: json['cabinType'] as String,
    images: (json['images'] as List<dynamic>)
        .map((value) => CabinImage.fromJson(value as Map<String, dynamic>))
        .toList(),
    amenities: (json['amenities'] as List<dynamic>)
        .map((value) => CabinAmenity.fromJson(value as Map<String, dynamic>))
        .toList(),
  );

  final int id;
  final String name;
  final String description;
  final String address;
  final double areaSquareMeters;
  final double pricePerNight;
  final int maxAdults;
  final int maxChildren;
  final int bedrooms;
  final int bathrooms;
  final String ownerName;
  final String city;
  final String cabinType;
  final List<CabinImage> images;
  final List<CabinAmenity> amenities;

  int get maxGuests => maxAdults + maxChildren;
}

class CabinImage {
  const CabinImage({
    required this.id,
    required this.url,
    required this.isCover,
    this.altText,
  });

  factory CabinImage.fromJson(Map<String, dynamic> json) => CabinImage(
    id: json['id'] as int,
    url: json['url'] as String,
    altText: json['altText'] as String?,
    isCover: json['isCover'] as bool,
  );

  final int id;
  final String url;
  final String? altText;
  final bool isCover;

  String get resolvedUrl {
    if (url.startsWith('http')) return url;
    return '${AppConfig.apiBaseUrl}${url.startsWith('/') ? '' : '/'}$url';
  }
}

class CabinAmenity {
  const CabinAmenity({required this.id, required this.name, this.icon});

  factory CabinAmenity.fromJson(Map<String, dynamic> json) => CabinAmenity(
    id: json['id'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );

  final int id;
  final String name;
  final String? icon;
}
