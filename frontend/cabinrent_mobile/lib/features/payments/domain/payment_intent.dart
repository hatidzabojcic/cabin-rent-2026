class PaymentIntent {
  const PaymentIntent({
    required this.paymentId,
    required this.reservationId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.clientSecret,
    required this.publishableKey,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
    paymentId: json['paymentId'] as int,
    reservationId: json['reservationId'] as int,
    amount: (json['amount'] as num).toDouble(),
    currency: json['currency'] as String,
    status: json['status'] as String,
    clientSecret: json['clientSecret'] as String,
    publishableKey: json['publishableKey'] as String,
  );

  final int paymentId;
  final int reservationId;
  final double amount;
  final String currency;
  final String status;
  final String clientSecret;
  final String publishableKey;
}
