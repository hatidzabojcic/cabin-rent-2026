import '../../../core/api/api_client.dart';
import '../domain/cabin.dart';

class CabinsRepository {
  CabinsRepository(this._api);
  final ApiClient _api;

  Future<List<Cabin>> getManagedCabins() async => (await _api.getList(
    '/api/cabins/manage',
    authenticated: true,
  )).map((item) => Cabin.fromJson(item as Map<String, dynamic>)).toList();

  Future<Cabin> getManagedCabin(int id) async => Cabin.fromJson(
    await _api.getObject('/api/cabins/manage/$id', authenticated: true),
  );

  Future<Cabin> create(CabinFormData data) async => Cabin.fromJson(
    await _api.post('/api/cabins', body: data.toJson(), authenticated: true),
  );

  Future<Cabin> update(int id, CabinFormData data) async => Cabin.fromJson(
    await _api.put('/api/cabins/$id', body: data.toJson(), authenticated: true),
  );

  Future<Cabin> setActive(int id, bool isActive) async => Cabin.fromJson(
    await _api.patch(
      '/api/cabins/$id/active',
      body: {'isActive': isActive},
      authenticated: true,
    ),
  );

  Future<CabinImage> uploadImage(
    int cabinId,
    List<int> bytes,
    String fileName,
  ) async => CabinImage.fromJson(
    await _api.uploadFile(
      '/api/cabins/$cabinId/images',
      bytes: bytes,
      fileName: fileName,
      authenticated: true,
    ),
  );

  Future<CabinImage> updateImage(
    int cabinId,
    CabinImage image, {
    required bool isCover,
    required int sortOrder,
  }) async => CabinImage.fromJson(
    await _api.patch(
      '/api/cabins/$cabinId/images/${image.id}',
      body: {
        'altText': image.altText,
        'sortOrder': sortOrder,
        'isCover': isCover,
      },
      authenticated: true,
    ),
  );

  Future<void> deleteImage(int cabinId, int imageId) =>
      _api.delete('/api/cabins/$cabinId/images/$imageId', authenticated: true);

  Future<List<CatalogOption>> getCities() => _catalog('/api/catalog/cities');
  Future<List<CatalogOption>> getCabinTypes() =>
      _catalog('/api/catalog/cabin-types');
  Future<List<CatalogOption>> getAmenities() =>
      _catalog('/api/catalog/amenities');

  Future<List<OwnerOption>> getOwners() async => (await _api.getList(
    '/api/users?role=Owner',
    authenticated: true,
  )).map((item) => OwnerOption.fromJson(item as Map<String, dynamic>)).toList();

  Future<List<CatalogOption>> _catalog(String path) async =>
      (await _api.getList(path))
          .map((item) => CatalogOption.fromJson(item as Map<String, dynamic>))
          .toList();
}
