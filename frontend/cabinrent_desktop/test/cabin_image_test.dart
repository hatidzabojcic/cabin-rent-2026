import 'package:cabinrent_desktop/features/cabins/domain/cabin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cabin image parses gallery metadata', () {
    final image = CabinImage.fromJson({
      'id': 7,
      'url': '/uploads/cabins/1/photo.webp',
      'altText': 'Dnevni boravak',
      'sortOrder': 2,
      'isCover': true,
    });
    expect(image.isCover, isTrue);
    expect(image.sortOrder, 2);
  });
}
