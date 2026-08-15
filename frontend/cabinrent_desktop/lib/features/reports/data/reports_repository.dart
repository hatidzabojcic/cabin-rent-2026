import '../../../core/api/api_client.dart';
import '../domain/annual_report.dart';

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
}
