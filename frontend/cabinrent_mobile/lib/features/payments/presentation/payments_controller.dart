import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/api/api_exception.dart';
import '../data/payments_repository.dart';

enum PaymentResult { succeeded, canceled, failed }

class PaymentsController extends ChangeNotifier {
  PaymentsController(this._repository);

  final PaymentsRepository _repository;

  bool isProcessing = false;
  String? errorMessage;

  Future<PaymentResult> pay(int reservationId) async {
    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final intent = await _repository.createIntent(reservationId);
      Stripe.publishableKey = intent.publishableKey;
      await Stripe.instance.applySettings();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'CabinRent',
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: false,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return PaymentResult.succeeded;
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        return PaymentResult.canceled;
      }
      errorMessage =
          error.error.localizedMessage ?? 'Stripe nije odobrio plaćanje.';
      return PaymentResult.failed;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return PaymentResult.failed;
    } catch (_) {
      errorMessage = 'Plaćanje trenutno nije moguće pokrenuti.';
      return PaymentResult.failed;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
