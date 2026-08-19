using System.Text.Json;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Notifications;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace CabinRent.Notifications;

public sealed class NotificationWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<NotificationWorker> _logger;
    private readonly ConnectionFactory _factory;
    private readonly string _queueName;

    public NotificationWorker(
        IServiceScopeFactory scopeFactory,
        IConfiguration configuration,
        ILogger<NotificationWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _queueName = Required(configuration, "RabbitMq:Queue");
        _factory = new ConnectionFactory
        {
            HostName = Required(configuration, "RabbitMq:Host"),
            Port = int.TryParse(configuration["RabbitMq:Port"], out var port) ? port :
                throw new InvalidOperationException("RabbitMQ port configuration is invalid."),
            UserName = Required(configuration, "RabbitMq:UserName"),
            Password = Required(configuration, "RabbitMq:Password"),
            AutomaticRecoveryEnabled = true
        };
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await EnsureDatabaseAsync(stoppingToken);
                await ConsumeAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception exception)
            {
                _logger.LogWarning(exception, "Notification worker čeka bazu ili RabbitMQ. Novi pokušaj za 5 sekundi.");
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }

    private async Task ConsumeAsync(CancellationToken cancellationToken)
    {
        await using var connection = await _factory.CreateConnectionAsync(cancellationToken);
        await using var channel = await connection.CreateChannelAsync(cancellationToken: cancellationToken);
        await channel.QueueDeclareAsync(_queueName, durable: true, exclusive: false, autoDelete: false, cancellationToken: cancellationToken);
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
                _logger.LogError(exception, "Obrada notification poruke nije uspjela.");
                var shouldRequeue = exception is not JsonException and not InvalidOperationException;
                await channel.BasicNackAsync(args.DeliveryTag, false, requeue: shouldRequeue, args.CancellationToken);
            }
        };
        await channel.BasicConsumeAsync(_queueName, autoAck: false, consumer, cancellationToken);
        _logger.LogInformation("Notification worker sluša red {QueueName}.", _queueName);
        await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken);
    }

    private async Task StoreAsync(NotificationEvent notificationEvent, CancellationToken cancellationToken)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
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
        await using var scope = _scopeFactory.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<CabinRentDbContext>().Database.MigrateAsync(cancellationToken);
    }

    private static string Required(IConfiguration configuration, string key) =>
        string.IsNullOrWhiteSpace(configuration[key])
            ? throw new InvalidOperationException($"Configuration value '{key}' is missing.")
            : configuration[key]!;
}
