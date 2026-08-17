using CabinRent.Services.Payments;
using Microsoft.Extensions.Options;
using Stripe;

namespace CabinRent.Infrastructure.Payments;

public sealed class StripePaymentGateway : IPaymentGateway
{
    private readonly StripeOptions _options;
    private readonly StripeClient? _client;

    public StripePaymentGateway(IOptions<StripeOptions> options)
    {
        _options = options.Value;
        if (!string.IsNullOrWhiteSpace(_options.SecretKey))
            _client = new StripeClient(_options.SecretKey);
    }

    public string PublishableKey => _options.PublishableKey;

    public async Task<GatewayPaymentIntent> CreateIntentAsync(
        long amountInMinorUnits,
        string currency,
        int reservationId,
        int paymentId,
        string idempotencyKey,
        CancellationToken cancellationToken = default)
    {
        EnsureConfigured();
        try
        {
            var service = new PaymentIntentService(_client);
            var intent = await service.CreateAsync(new PaymentIntentCreateOptions
            {
                Amount = amountInMinorUnits,
                Currency = currency.ToLowerInvariant(),
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions { Enabled = true },
                Metadata = new Dictionary<string, string>
                {
                    ["reservation_id"] = reservationId.ToString(),
                    ["payment_id"] = paymentId.ToString()
                }
            }, new RequestOptions { IdempotencyKey = idempotencyKey }, cancellationToken);

            return Map(intent);
        }
        catch (StripeException exception)
        {
            throw new PaymentProviderException("Stripe trenutno nije mogao pripremiti plaćanje. Pokušajte ponovo.", exception);
        }
    }

    public async Task<GatewayPaymentIntent> GetIntentAsync(string providerReference, CancellationToken cancellationToken = default)
    {
        EnsureConfigured();
        try
        {
            var intent = await new PaymentIntentService(_client).GetAsync(providerReference, cancellationToken: cancellationToken);
            return Map(intent);
        }
        catch (StripeException exception)
        {
            throw new PaymentProviderException("Stripe trenutno nije mogao provjeriti plaćanje. Pokušajte ponovo.", exception);
        }
    }

    private void EnsureConfigured()
    {
        if (_client is null || string.IsNullOrWhiteSpace(_options.PublishableKey))
            throw new PaymentConfigurationException("Stripe sandbox nije konfigurisan. Postavite STRIPE_SECRET_KEY i STRIPE_PUBLISHABLE_KEY u .env datoteci.");
        if (!_options.SecretKey.StartsWith("sk_test_", StringComparison.Ordinal) ||
            !_options.PublishableKey.StartsWith("pk_test_", StringComparison.Ordinal))
            throw new PaymentConfigurationException("Za razvoj je dozvoljena samo Stripe sandbox konfiguracija (test ključevi).");
    }

    private static GatewayPaymentIntent Map(PaymentIntent intent) =>
        new(intent.Id, intent.ClientSecret ?? throw new InvalidOperationException("Stripe nije vratio client secret."), intent.Status);
}
