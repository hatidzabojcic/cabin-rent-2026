using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Notifications;

namespace CabinRent.Infrastructure.Notifications;

public static class NotificationOutboxExtensions
{
    public static void EnqueueNotification(this CabinRentDbContext dbContext, NotificationEvent notification) =>
        dbContext.NotificationOutbox.Add(new NotificationOutbox
        {
            EventId = notification.EventId,
            RecipientUserId = notification.RecipientUserId,
            Type = notification.Type,
            Title = notification.Title,
            Message = notification.Message,
            RelatedEntityType = notification.RelatedEntityType,
            RelatedEntityId = notification.RelatedEntityId,
            OccurredAtUtc = notification.OccurredAtUtc
        });
}
