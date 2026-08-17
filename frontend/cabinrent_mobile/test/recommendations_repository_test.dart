import 'dart:convert';

import 'package:cabinrent_mobile/core/api/api_client.dart';
import 'package:cabinrent_mobile/features/recommendations/data/recommendations_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads personalized cabin recommendations', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/recommendations');
      expect(request.url.queryParameters['limit'], '6');
      expect(request.headers['Authorization'], 'Bearer guest-token');
      return http.Response(
        jsonEncode([
          {
            'cabinId': 4,
            'name': 'Plivsko gnijezdo',
            'city': 'Jajce',
            'pricePerNight': 120.0,
            'maxGuests': 5,
            'averageRating': 4.8,
            'coverImageUrl': '/uploads/cabins/pliva.jpg',
            'score': 12.5,
            'reason': 'Slično je vikendicama koje ste ranije odabrali.',
            'isPersonalized': true,
          },
        ]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final api = ApiClient(client: client)..accessToken = 'guest-token';
    final repository = RecommendationsRepository(api);

    final recommendations = await repository.getRecommendations();

    expect(recommendations, hasLength(1));
    expect(recommendations.single.cabinId, 4);
    expect(recommendations.single.isPersonalized, isTrue);
    expect(recommendations.single.cabin.id, 4);
    expect(recommendations.single.cabin.averageRating, 4.8);
  });
}
