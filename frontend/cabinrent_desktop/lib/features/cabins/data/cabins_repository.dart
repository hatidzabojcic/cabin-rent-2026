import '../../../core/api/api_client.dart';
import '../domain/cabin.dart';

class CabinsRepository {
  CabinsRepository(this._api);
  final ApiClient _api;

  Future<List<Cabin>> getCabins({String? search}) async {
    final query = search == null || search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final json = await _api.getObject('/api/cabins$query');
    return (json['items'] as List<dynamic>)
        .map((item) => Cabin.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
