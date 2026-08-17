import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/features/reviews/data/reviews_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('submits a review for a completed reservation', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/reviews');
      expect(request.headers['Authorization'], 'Bearer guest-token');
      expect(jsonDecode(request.body), {
        'reservationId': 2,
        'rating': 4,
        'comment': 'Veoma ugodan boravak.',
      });
      return http.Response(
        jsonEncode({
          'id': 8,
          'reservationId': 2,
          'cabinId': 2,
          'cabinName': 'Neretva retreat',
          'guestId': 3,
          'guestName': 'Demo Guest',
          'guestEmail': 'guest@cabinrent.local',
          'rating': 4,
          'comment': 'Veoma ugodan boravak.',
          'isApproved': false,
          'createdAtUtc': '2026-08-17T20:00:00Z',
        }),
        201,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';
    final repository = ReviewsRepository(api);

    final review = await repository.create(
      reservationId: 2,
      rating: 4,
      comment: '  Veoma ugodan boravak.  ',
    );

    expect(review.reservationId, 2);
    expect(review.rating, 4);
    expect(review.isApproved, isFalse);
  });
}
