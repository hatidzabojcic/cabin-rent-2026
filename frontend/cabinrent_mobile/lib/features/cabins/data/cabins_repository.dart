import '../../../core/api/api_client.dart';
import '../domain/cabin_details.dart';
import '../domain/cabin_summary.dart';

class CabinsRepository {
  CabinsRepository(this._api);
  final ApiClient _api;
  Future<List<CabinSummary>> getCabins({
    String? search,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
  }) async {
    final query = Uri(
      queryParameters: {
        'pageSize': '50',
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (checkIn != null) 'checkIn': _dateOnly(checkIn),
        if (checkOut != null) 'checkOut': _dateOnly(checkOut),
        if (guests != null) 'guests': guests.toString(),
      },
    ).query;
    final result = await _api.getObject('/api/cabins?$query');
    return (result['items'] as List<dynamic>)
        .map((x) => CabinSummary.fromJson(x as Map<String, dynamic>))
        .toList();
  }

  Future<CabinDetails> getCabin(int id) async {
    final result = await _api.getObject('/api/cabins/$id');
    return CabinDetails.fromJson(result);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
