using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Notifications;
using CabinRent.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.API.Infrastructure;

public sealed class NotificationOutboxWorker(
    IServiceScopeFactory scopeFactory,
    INotificationEventPublisher publisher,
    ILogger<NotificationOutboxWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var publishedAny = await PublishPendingAsync(stoppingToken);
                await Task.Delay(publishedAny ? TimeSpan.FromSeconds(1) : TimeSpan.FromSeconds(15), stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception exception)
            {
                logger.LogWarning(exception, "Slanje outbox obavijesti trenutno nije dostupno. Novi pokušaj slijedi kasnije.");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }

    private async Task<bool> PublishPendingAsync(CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CabinRentDbContext>();
        var now = DateTime.UtcNow;
        var messages = await dbContext.NotificationOutbox
            .Where(x => x.PublishedAtUtc == null && (x.NextAttemptAtUtc == null || x.NextAttemptAtUtc <= now))
            .OrderBy(x => x.CreatedAtUtc)
            .Take(20)
            .ToListAsync(cancellationToken);

        foreach (var message in messages)
        {
            try
            {
                await publisher.PublishAsync(new NotificationEvent(
                    message.EventId,
                    message.RecipientUserId,
                    message.Type,
                    message.Title,
                    message.Message,
                    message.RelatedEntityType,
                    message.RelatedEntityId,
                    message.OccurredAtUtc), cancellationToken);
                message.PublishedAtUtc = DateTime.UtcNow;
                message.LastError = null;
            }
            catch (Exception exception)
            {
                message.AttemptCount++;
                var delaySeconds = Math.Min(300, 15 * Math.Pow(2, Math.Min(message.AttemptCount - 1, 5)));
                message.NextAttemptAtUtc = DateTime.UtcNow.AddSeconds(delaySeconds);
                message.LastError = exception.Message[..Math.Min(exception.Message.Length, 1000)];
                logger.LogWarning("Outbox obavijest {EventId} čeka RabbitMQ. Pokušaj {AttemptCount}.", message.EventId, message.AttemptCount);
            }

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return messages.Count > 0;
    }
}
