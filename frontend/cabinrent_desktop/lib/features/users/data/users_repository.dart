import '../../../core/api/api_client.dart';
import '../domain/managed_user.dart';

class UsersRepository {
  UsersRepository(this._api);
  final ApiClient _api;

  Future<List<ManagedUser>> getUsers({
    String? search,
    String? role,
    bool? isActive,
  }) async {
    final parameters = <String, String>{
      'pageSize': '100',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (role != null && role.isNotEmpty) 'role': role,
      if (isActive != null) 'isActive': isActive.toString(),
    };
    final query = parameters.isEmpty
        ? ''
        : '?${Uri(queryParameters: parameters).query}';
    return (await _api.getPagedItems(
          '/api/users/management$query',
          authenticated: true,
        ))
        .map((item) => ManagedUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ManagedUser> setActive(int id, bool isActive) async =>
      ManagedUser.fromJson(
        await _api.patch(
          '/api/users/$id/status',
          body: {'isActive': isActive},
          authenticated: true,
        ),
      );

  Future<ManagedUser> create(Map<String, dynamic> data) async =>
      ManagedUser.fromJson(
        await _api.post('/api/users', body: data, authenticated: true),
      );

  Future<ManagedUser> update(int id, Map<String, dynamic> data) async =>
      ManagedUser.fromJson(
        await _api.put('/api/users/$id', body: data, authenticated: true),
      );

  Future<void> delete(int id) =>
      _api.delete('/api/users/$id', authenticated: true);
}
