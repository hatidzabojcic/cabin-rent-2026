import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/features/reviews/data/reviews_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final reviewJson = {
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
  };

  test('loads only public reviews for a cabin', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/reviews');
      expect(request.url.queryParameters['cabinId'], '2');
      expect(request.headers['Authorization'], isNull);
      return http.Response(
        jsonEncode([
          {...reviewJson, 'isApproved': true},
        ]),
        200,
      );
    });

    final reviews = await ReviewsRepository(
      ApiClient(client: client),
    ).getApprovedForCabin(2);

    expect(reviews, hasLength(1));
    expect(reviews.single.isApproved, isTrue);
  });

  test('loads all reviews submitted by the signed-in guest', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/reviews/mine');
      expect(request.headers['Authorization'], 'Bearer guest-token');
      return http.Response(jsonEncode([reviewJson]), 200);
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';

    final reviews = await ReviewsRepository(api).getMine();

    expect(reviews.single.reservationId, 2);
    expect(reviews.single.isApproved, isFalse);
  });

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
        jsonEncode(reviewJson),
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
