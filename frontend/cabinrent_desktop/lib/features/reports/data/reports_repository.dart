import '../../../core/api/api_client.dart';
import '../domain/annual_report.dart';
import '../domain/top_guests_report.dart';

class ReportsRepository {
  ReportsRepository(this._api);
  final ApiClient _api;

  Future<AnnualReport> getAnnualReport(int year, {int? cabinId}) async {
    final query = Uri(
      queryParameters: {
        'year': year.toString(),
        if (cabinId != null) 'cabinId': cabinId.toString(),
      },
    ).query;
    return AnnualReport.fromJson(
      await _api.getObject('/api/reports/annual?$query', authenticated: true),
    );
  }

  Future<TopGuestsReport> getTopGuests(
    int year, {
    int? cabinId,
    int limit = 20,
  }) async {
    final query = Uri(
      queryParameters: {
        'year': year.toString(),
        'limit': limit.toString(),
        if (cabinId != null) 'cabinId': cabinId.toString(),
      },
    ).query;
    return TopGuestsReport.fromJson(
      await _api.getObject(
        '/api/reports/top-guests?$query',
        authenticated: true,
      ),
    );
  }
}
