using CabinRent.Infrastructure.Payments;
using CabinRent.Services.Payments;
using Microsoft.Extensions.Options;

namespace CabinRent.API.Infrastructure;

public sealed class StripeReconciliationWorker(
    IServiceScopeFactory scopeFactory,
    IOptions<StripeOptions> stripeOptions,
    ILogger<StripeReconciliationWorker> logger) : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(30);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (string.IsNullOrWhiteSpace(stripeOptions.Value.SecretKey))
        {
            logger.LogWarning("Automatsko Stripe usklađivanje nije pokrenuto jer Stripe secret key nije konfigurisan.");
            return;
        }

        await ReconcileAsync(stoppingToken);
        using var timer = new PeriodicTimer(Interval);
        while (await timer.WaitForNextTickAsync(stoppingToken))
            await ReconcileAsync(stoppingToken);
    }

    private async Task ReconcileAsync(CancellationToken cancellationToken)
    {
        try
        {
            await using var scope = scopeFactory.CreateAsyncScope();
            var paymentService = scope.ServiceProvider.GetRequiredService<IPaymentService>();
            var changed = await paymentService.ReconcilePendingAsync(cancellationToken);
            if (changed > 0)
                logger.LogInformation("Automatski je usklađeno {Count} Stripe plaćanja/refunda.", changed);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
        }
        catch (Exception exception)
        {
            logger.LogWarning(exception,
                "Automatsko Stripe usklađivanje trenutno nije dostupno; API nastavlja rad i pokušat će ponovo.");
        }
    }
}
