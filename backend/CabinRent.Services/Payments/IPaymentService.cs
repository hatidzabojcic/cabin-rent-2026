using CabinRent.Model.Payments;

namespace CabinRent.Services.Payments;

public interface IPaymentService
{
    Task<PaymentIntentDto> CreateIntentAsync(int reservationId, int guestId, CancellationToken cancellationToken = default);
    Task<PaymentWebhookResultDto> ProcessWebhookAsync(string payload, string signature, CancellationToken cancellationToken = default);
}

public interface IPaymentGateway
{
    string PublishableKey { get; }
    Task<GatewayPaymentIntent> CreateIntentAsync(
        long amountInMinorUnits,
        string currency,
        int reservationId,
        int paymentId,
        string idempotencyKey,
        CancellationToken cancellationToken = default);
    Task<GatewayPaymentIntent> GetIntentAsync(string providerReference, CancellationToken cancellationToken = default);
    GatewayWebhookEvent ParseWebhook(string payload, string signature);
}

public sealed record GatewayPaymentIntent(string Id, string ClientSecret, string Status);
public sealed record GatewayWebhookEvent(
    string EventId,
    string Type,
    string? PaymentIntentId,
    long? AmountReceived,
    string? Currency,
    string? FailureMessage);

public sealed class PaymentProviderException(string message, Exception? innerException = null) : Exception(message, innerException);

public sealed class PaymentConfigurationException(string message) : Exception(message);

public sealed class InvalidPaymentWebhookException(string message, Exception? innerException = null) : Exception(message, innerException);
