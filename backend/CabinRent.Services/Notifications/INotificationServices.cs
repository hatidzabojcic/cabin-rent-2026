using CabinRent.Model.Notifications;

namespace CabinRent.Services.Notifications;

public interface INotificationEventPublisher
{
    Task PublishAsync(NotificationEvent notification, CancellationToken cancellationToken = default);
}

public interface INotificationService
{
    Task<IReadOnlyCollection<NotificationDto>> GetAsync(int userId, bool? isRead, CancellationToken cancellationToken = default);
    Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default);
    Task<bool> MarkReadAsync(int id, int userId, CancellationToken cancellationToken = default);
    Task<int> MarkAllReadAsync(int userId, CancellationToken cancellationToken = default);
}
