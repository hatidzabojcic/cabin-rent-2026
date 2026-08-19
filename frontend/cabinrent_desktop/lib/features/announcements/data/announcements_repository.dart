import '../../../core/api/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._api);
  final ApiClient _api;

  Future<List<Announcement>> get({String search = ''}) async =>
      (await _api.getPagedItems(
        '/api/announcements/management?pageSize=100&search=${Uri.encodeQueryComponent(search)}',
        authenticated: true,
      )).map((x) => Announcement.fromJson(x as Map<String, dynamic>)).toList();

  Future<void> save({Announcement? current, required Map<String, dynamic> body}) async {
    if (current == null) {
      await _api.post('/api/announcements', body: body, authenticated: true);
    } else {
      await _api.put('/api/announcements/${current.id}', body: body, authenticated: true);
    }
  }

  Future<void> delete(int id) => _api.delete('/api/announcements/$id', authenticated: true);
}
