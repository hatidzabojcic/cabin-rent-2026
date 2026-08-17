namespace CabinRent.Model.Payments;

public sealed record PaymentIntentDto(
    int PaymentId,
    int ReservationId,
    decimal Amount,
    string Currency,
    string Status,
    string ClientSecret,
    string PublishableKey);
