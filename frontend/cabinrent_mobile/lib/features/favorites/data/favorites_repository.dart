import '../../../core/api/api_client.dart';
import '../domain/favorite.dart';

class FavoritesRepository {
  FavoritesRepository(this._api);

  final ApiClient _api;

  Future<List<Favorite>> getFavorites() async => (await _api.getPagedItems(
    '/api/favorites?pageSize=100',
    authenticated: true,
  )).map((item) => Favorite.fromJson(item as Map<String, dynamic>)).toList();

  Future<Favorite> add(int cabinId) async => Favorite.fromJson(
    await _api.post(
      '/api/favorites',
      authenticated: true,
      body: {'cabinId': cabinId},
    ),
  );

  Future<void> remove(int cabinId) =>
      _api.delete('/api/favorites/$cabinId', authenticated: true);
}
