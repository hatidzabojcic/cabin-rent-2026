using System.Text.Json;
using CabinRent.Infrastructure.Notifications;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Notifications;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace CabinRent.Notifications;

public sealed class NotificationWorker(
    IServiceScopeFactory scopeFactory,
    IConfiguration configuration,
    ILogger<NotificationWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await EnsureDatabaseAsync(stoppingToken);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ConsumeAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception exception)
            {
                logger.LogError(exception, "Notification worker nije povezan. Novi pokušaj za 5 sekundi.");
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }

    private async Task ConsumeAsync(CancellationToken cancellationToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = configuration["RabbitMq:Host"] ?? "localhost",
            Port = int.TryParse(configuration["RabbitMq:Port"], out var port) ? port : 5672,
            UserName = configuration["RabbitMq:UserName"] ?? "guest",
            Password = configuration["RabbitMq:Password"] ?? "guest",
            AutomaticRecoveryEnabled = true
        };
        await using var connection = await factory.CreateConnectionAsync(cancellationToken);
        await using var channel = await connection.CreateChannelAsync(cancellationToken: cancellationToken);
        await channel.QueueDeclareAsync(RabbitMqNotificationPublisher.QueueName, durable: true, exclusive: false, autoDelete: false, cancellationToken: cancellationToken);
        await channel.BasicQosAsync(0, 10, false, cancellationToken);

        var consumer = new AsyncEventingBasicConsumer(channel);
        consumer.ReceivedAsync += async (_, args) =>
        {
            try
            {
                var notificationEvent = JsonSerializer.Deserialize<NotificationEvent>(args.Body.Span)
                    ?? throw new InvalidOperationException("RabbitMQ poruka nije validna.");
                await StoreAsync(notificationEvent, args.CancellationToken);
                await channel.BasicAckAsync(args.DeliveryTag, false, args.CancellationToken);
            }
            catch (Exception exception)
            {
                logger.LogError(exception, "Obrada notification poruke nije uspjela.");
                var shouldRequeue = exception is not JsonException and not InvalidOperationException;
                await channel.BasicNackAsync(args.DeliveryTag, false, requeue: shouldRequeue, args.CancellationToken);
            }
        };
        await channel.BasicConsumeAsync(RabbitMqNotificationPublisher.QueueName, autoAck: false, consumer, cancellationToken);
        logger.LogInformation("Notification worker sluša red {QueueName}.", RabbitMqNotificationPublisher.QueueName);
        await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken);
    }

    private async Task StoreAsync(NotificationEvent notificationEvent, CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CabinRentDbContext>();
        if (await dbContext.Notifications.AnyAsync(x => x.EventId == notificationEvent.EventId, cancellationToken)) return;
        if (!await dbContext.Users.AnyAsync(x => x.Id == notificationEvent.RecipientUserId, cancellationToken))
            throw new InvalidOperationException("Primalac obavijesti ne postoji.");
        dbContext.Notifications.Add(new Notification
        {
            EventId = notificationEvent.EventId,
            UserId = notificationEvent.RecipientUserId,
            Type = notificationEvent.Type,
            Title = notificationEvent.Title,
            Message = notificationEvent.Message,
            RelatedEntityType = notificationEvent.RelatedEntityType,
            RelatedEntityId = notificationEvent.RelatedEntityId,
            CreatedAtUtc = notificationEvent.OccurredAtUtc
        });
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task EnsureDatabaseAsync(CancellationToken cancellationToken)
    {
        await using var scope = scopeFactory.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<CabinRentDbContext>().Database.MigrateAsync(cancellationToken);
    }
}
