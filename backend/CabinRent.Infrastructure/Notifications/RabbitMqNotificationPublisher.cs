using System.Text.Json;
using CabinRent.Model.Notifications;
using CabinRent.Services.Notifications;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace CabinRent.Infrastructure.Notifications;

public sealed class RabbitMqNotificationPublisher : INotificationEventPublisher
{
    private readonly ConnectionFactory _factory;
    private readonly string _queueName;

    public RabbitMqNotificationPublisher(IConfiguration configuration)
    {
        _queueName = Required(configuration, "RabbitMq:Queue");
        _factory = new ConnectionFactory
        {
            HostName = Required(configuration, "RabbitMq:Host"),
            Port = int.TryParse(configuration["RabbitMq:Port"], out var port) ? port :
                throw new InvalidOperationException("RabbitMQ port configuration is invalid."),
            UserName = Required(configuration, "RabbitMq:UserName"),
            Password = Required(configuration, "RabbitMq:Password")
        };
    }

    public async Task PublishAsync(NotificationEvent notification, CancellationToken cancellationToken = default)
    {
        await using var connection = await _factory.CreateConnectionAsync(cancellationToken);
        await using var channel = await connection.CreateChannelAsync(cancellationToken: cancellationToken);
        await channel.QueueDeclareAsync(_queueName, durable: true, exclusive: false, autoDelete: false, cancellationToken: cancellationToken);
        var properties = new BasicProperties { Persistent = true, ContentType = "application/json", MessageId = notification.EventId.ToString() };
        var body = JsonSerializer.SerializeToUtf8Bytes(notification);
        await channel.BasicPublishAsync(string.Empty, _queueName, mandatory: false, properties, body, cancellationToken);
    }

    private static string Required(IConfiguration configuration, string key) =>
        string.IsNullOrWhiteSpace(configuration[key])
            ? throw new InvalidOperationException($"Configuration value '{key}' is missing.")
            : configuration[key]!;
}
