import '../../../core/api/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._api); final ApiClient _api;
  Future<List<Announcement>> getPublished() async =>
      (await _api.getPagedItems('/api/announcements?pageSize=10', authenticated: true))
          .map((x) => Announcement.fromJson(x as Map<String, dynamic>)).toList();
}
