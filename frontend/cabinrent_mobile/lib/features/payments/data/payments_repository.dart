import '../../../core/api/api_client.dart';
import '../domain/payment_intent.dart';

class PaymentsRepository {
  PaymentsRepository(this._api);

  final ApiClient _api;

  Future<PaymentIntent> createIntent(int reservationId) async =>
      PaymentIntent.fromJson(
        await _api.post(
          '/api/payments/reservations/$reservationId/intent',
          authenticated: true,
        ),
      );
}
