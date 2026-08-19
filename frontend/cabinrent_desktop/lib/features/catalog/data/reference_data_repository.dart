import '../../../core/api/api_client.dart';
import '../domain/reference_data.dart';

class ReferenceDataRepository {
  ReferenceDataRepository(this._api);
  final ApiClient _api;

  Future<ReferencePage> getPage(
    ReferenceKind kind, {
    required int page,
    int pageSize = 20,
    String? search,
  }) async {
    final query = Uri(
      queryParameters: {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    ).query;
    final json = await _api.getObject(
      '/api/catalog/${kind.path}?$query',
      authenticated: true,
    );
    return ReferencePage(
      items: (json['items'] as List<dynamic>)
          .map(
            (item) =>
                ReferenceItem.fromJson(item as Map<String, dynamic>, kind),
          )
          .toList(),
      totalCount: json['totalCount'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }

  Future<List<ReferenceItem>> getCountries() async =>
      (await getPage(ReferenceKind.countries, page: 1, pageSize: 100)).items;

  Future<void> create(ReferenceKind kind, Map<String, dynamic> body) =>
      _api.post('/api/catalog/${kind.path}', body: body, authenticated: true);

  Future<void> update(ReferenceKind kind, int id, Map<String, dynamic> body) =>
      _api.put(
        '/api/catalog/${kind.path}/$id',
        body: body,
        authenticated: true,
      );

  Future<void> delete(ReferenceKind kind, int id) =>
      _api.delete('/api/catalog/${kind.path}/$id', authenticated: true);
}
