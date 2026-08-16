import 'package:cabinrent_mobile/features/cabins/domain/cabin_details.dart';
import 'package:cabinrent_mobile/features/cabins/domain/cabin_search_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses cabin details with gallery and amenities', () {
    final cabin = CabinDetails.fromJson({
      'id': 2,
      'name': 'Neretva retreat',
      'description': 'Kuća za odmor uz rijeku.',
      'address': 'Glavatičevo bb',
      'areaSquareMeters': 95,
      'pricePerNight': 220.0,
      'maxAdults': 6,
      'maxChildren': 3,
      'bedrooms': 3,
      'bathrooms': 2,
      'ownerName': 'Demo Owner',
      'city': 'Konjic',
      'cabinType': 'Kuća uz jezero',
      'images': [
        {
          'id': 10,
          'url': '/uploads/cabins/neretva.jpg',
          'altText': 'Dnevni boravak',
          'sortOrder': 0,
          'isCover': true,
        },
      ],
      'amenities': [
        {'id': 1, 'name': 'Wi-Fi', 'icon': 'wifi'},
      ],
    });

    expect(cabin.maxGuests, 9);
    expect(cabin.images.single.isCover, isTrue);
    expect(cabin.amenities.single.name, 'Wi-Fi');
  });

  test('calculates the number of nights for availability criteria', () {
    final criteria = CabinSearchCriteria(
      checkIn: DateTime(2026, 9, 10),
      checkOut: DateTime(2026, 9, 14),
      guests: 4,
    );

    expect(criteria.nights, 4);
    expect(criteria.guests, 4);
  });
}
