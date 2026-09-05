enum ReferenceKind { countries, cities, cabinTypes, amenities, roles }

extension ReferenceKindInfo on ReferenceKind {
  String get label => switch (this) {
    ReferenceKind.countries => 'Drzave',
    ReferenceKind.cities => 'Gradovi',
    ReferenceKind.cabinTypes => 'Tipovi vikendica',
    ReferenceKind.amenities => 'Pogodnosti',
    ReferenceKind.roles => 'Uloge',
  };

  String get path => switch (this) {
    ReferenceKind.countries => 'countries',
    ReferenceKind.cities => 'cities',
    ReferenceKind.cabinTypes => 'cabin-types',
    ReferenceKind.amenities => 'amenities',
    ReferenceKind.roles => 'roles',
  };
}

class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.name,
    this.code,
    this.isoCode,
    this.postalCode,
    this.countryId,
    this.countryName,
    this.description,
    this.icon,
  });

  factory ReferenceItem.fromJson(
    Map<String, dynamic> json,
    ReferenceKind kind,
  ) => ReferenceItem(
    id: json['id'] as int,
    name: json['name'] as String,
    code: json['code'] as String?,
    isoCode: json['isoCode'] as String?,
    postalCode: json['postalCode'] as String?,
    countryId: json['countryId'] as int?,
    countryName: json['countryName'] as String?,
    description: json['description'] as String?,
    icon: json['icon'] as String?,
  );

  final int id;
  final String name;
  final String? code;
  final String? isoCode;
  final String? postalCode;
  final int? countryId;
  final String? countryName;
  final String? description;
  final String? icon;

  String get details =>
      (code == null
          ? null
          : [code, description].whereType<String>().join(' - ')) ??
      isoCode ??
      [postalCode, countryName].whereType<String>().join(' - ').nullIfEmpty ??
      description ??
      icon ??
      '-';
}

class ReferencePage {
  const ReferencePage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<ReferenceItem> items;
  final int totalCount;
  final int page;
  final int pageSize;
  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
