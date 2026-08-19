namespace CabinRent.Model.Payments;

public sealed record PaymentIntentDto(
    int PaymentId,
    int ReservationId,
    decimal Amount,
    string Currency,
    string Status,
    string ClientSecret,
    string PublishableKey);

public sealed record PaymentWebhookResultDto(string EventId, string Outcome);

public sealed record PaymentConfirmationDto(
    int PaymentId,
    int ReservationId,
    string Status,
    decimal PaidAmount,
    string Currency);
