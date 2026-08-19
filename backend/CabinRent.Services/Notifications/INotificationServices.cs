using CabinRent.Model.Notifications;
using CabinRent.Model.Common;

namespace CabinRent.Services.Notifications;

public interface INotificationEventPublisher
{
    Task PublishAsync(NotificationEvent notification, CancellationToken cancellationToken = default);
}

public interface INotificationService
{
    Task<PagedResult<NotificationDto>> GetAsync(PageRequest paging, int userId, bool? isRead, CancellationToken cancellationToken = default);
    Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default);
    Task<bool> MarkReadAsync(int id, int userId, CancellationToken cancellationToken = default);
    Task<int> MarkAllReadAsync(int userId, CancellationToken cancellationToken = default);
}
