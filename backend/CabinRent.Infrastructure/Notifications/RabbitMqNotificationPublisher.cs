using System.Text.Json;
using CabinRent.Model.Notifications;
using CabinRent.Services.Notifications;
using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;

namespace CabinRent.Infrastructure.Notifications;

public sealed class RabbitMqNotificationPublisher(IConfiguration configuration) : INotificationEventPublisher
{
    public const string QueueName = "cabinrent.notifications";

    public async Task PublishAsync(NotificationEvent notification, CancellationToken cancellationToken = default)
    {
        var factory = new ConnectionFactory
        {
            HostName = configuration["RabbitMq:Host"] ?? "localhost",
            Port = int.TryParse(configuration["RabbitMq:Port"], out var port) ? port : 5672,
            UserName = configuration["RabbitMq:UserName"] ?? "guest",
            Password = configuration["RabbitMq:Password"] ?? "guest"
        };
        await using var connection = await factory.CreateConnectionAsync(cancellationToken);
        await using var channel = await connection.CreateChannelAsync(cancellationToken: cancellationToken);
        await channel.QueueDeclareAsync(QueueName, durable: true, exclusive: false, autoDelete: false, cancellationToken: cancellationToken);
        var properties = new BasicProperties { Persistent = true, ContentType = "application/json", MessageId = notification.EventId.ToString() };
        var body = JsonSerializer.SerializeToUtf8Bytes(notification);
        await channel.BasicPublishAsync(string.Empty, QueueName, mandatory: false, properties, body, cancellationToken);
    }
}
