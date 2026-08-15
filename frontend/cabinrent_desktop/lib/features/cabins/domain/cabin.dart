class Cabin {
  const Cabin({
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
    required this.isActive,
    required this.ownerId,
    required this.ownerName,
    required this.ownerIsActive,
    required this.cityId,
    required this.city,
    required this.cabinTypeId,
    required this.cabinType,
    required this.amenityIds,
    this.latitude,
    this.longitude,
    required this.images,
  });

  factory Cabin.fromJson(Map<String, dynamic> json) => Cabin(
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
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isActive: json['isActive'] as bool,
    ownerId: json['ownerId'] as int,
    ownerName: json['ownerName'] as String,
    ownerIsActive: json['ownerIsActive'] as bool,
    cityId: json['cityId'] as int,
    city: json['city'] as String,
    cabinTypeId: json['cabinTypeId'] as int,
    cabinType: json['cabinType'] as String,
    images: (json['images'] as List<dynamic>)
        .map((image) => CabinImage.fromJson(image as Map<String, dynamic>))
        .toList(),
    amenityIds: (json['amenities'] as List<dynamic>)
        .map((item) => (item as Map<String, dynamic>)['id'] as int)
        .toSet(),
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
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final int ownerId;
  final String ownerName;
  final bool ownerIsActive;
  final int cityId;
  final String city;
  final int cabinTypeId;
  final String cabinType;
  final List<CabinImage> images;
  final Set<int> amenityIds;

  String? get coverImageUrl =>
      images.where((image) => image.isCover).firstOrNull?.url;
  bool get isPubliclyAvailable => isActive && ownerIsActive;
}

class CabinImage {
  const CabinImage({
    required this.id,
    required this.url,
    required this.sortOrder,
    required this.isCover,
    this.altText,
  });
  factory CabinImage.fromJson(Map<String, dynamic> json) => CabinImage(
    id: json['id'] as int,
    url: json['url'] as String,
    altText: json['altText'] as String?,
    sortOrder: json['sortOrder'] as int,
    isCover: json['isCover'] as bool,
  );
  final int id;
  final String url;
  final String? altText;
  final int sortOrder;
  final bool isCover;
}

class CatalogOption {
  const CatalogOption(this.id, this.name);
  factory CatalogOption.fromJson(Map<String, dynamic> json) =>
      CatalogOption(json['id'] as int, json['name'] as String);
  final int id;
  final String name;
}

class OwnerOption {
  const OwnerOption(this.id, this.name);
  factory OwnerOption.fromJson(Map<String, dynamic> json) => OwnerOption(
    json['id'] as int,
    '${json['firstName']} ${json['lastName']}',
  );
  final int id;
  final String name;
}

class CabinFormData {
  CabinFormData({
    required this.name,
    required this.description,
    required this.address,
    required this.areaSquareMeters,
    required this.pricePerNight,
    required this.maxAdults,
    required this.maxChildren,
    required this.bedrooms,
    required this.bathrooms,
    required this.cityId,
    required this.cabinTypeId,
    required this.amenityIds,
    this.ownerId,
    this.latitude,
    this.longitude,
    this.coverImageUrl,
  });
  final String name;
  final String description;
  final String address;
  final double areaSquareMeters;
  final double pricePerNight;
  final int maxAdults;
  final int maxChildren;
  final int bedrooms;
  final int bathrooms;
  final int cityId;
  final int cabinTypeId;
  final int? ownerId;
  final double? latitude;
  final double? longitude;
  final Set<int> amenityIds;
  final String? coverImageUrl;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'address': address,
    'areaSquareMeters': areaSquareMeters,
    'pricePerNight': pricePerNight,
    'maxAdults': maxAdults,
    'maxChildren': maxChildren,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'cityId': cityId,
    'cabinTypeId': cabinTypeId,
    'ownerId': ownerId,
    'latitude': latitude,
    'longitude': longitude,
    'amenityIds': amenityIds.toList(),
    'coverImageUrl': coverImageUrl?.trim().isEmpty == true
        ? null
        : coverImageUrl?.trim(),
  };
}
