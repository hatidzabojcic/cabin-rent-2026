using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Notifications;
using CabinRent.Services.Notifications;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Notifications;

public sealed class NotificationService(CabinRentDbContext dbContext) : INotificationService
{
    public async Task<IReadOnlyCollection<NotificationDto>> GetAsync(int userId, bool? isRead, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Notifications.AsNoTracking().Where(x => x.UserId == userId);
        if (isRead.HasValue) query = query.Where(x => x.IsRead == isRead.Value);
        return await query.OrderByDescending(x => x.CreatedAtUtc).Take(100).Select(ToDto()).ToListAsync(cancellationToken);
    }

    public Task<int> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default) =>
        dbContext.Notifications.CountAsync(x => x.UserId == userId && !x.IsRead, cancellationToken);

    public async Task<bool> MarkReadAsync(int id, int userId, CancellationToken cancellationToken = default)
    {
        var notification = await dbContext.Notifications.SingleOrDefaultAsync(x => x.Id == id && x.UserId == userId, cancellationToken);
        if (notification is null) return false;
        if (!notification.IsRead)
        {
            notification.IsRead = true;
            notification.ReadAtUtc = DateTime.UtcNow;
            notification.UpdatedAtUtc = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        return true;
    }

    public async Task<int> MarkAllReadAsync(int userId, CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        return await dbContext.Notifications.Where(x => x.UserId == userId && !x.IsRead)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(x => x.IsRead, true)
                .SetProperty(x => x.ReadAtUtc, now)
                .SetProperty(x => x.UpdatedAtUtc, now), cancellationToken);
    }

    private static System.Linq.Expressions.Expression<Func<Notification, NotificationDto>> ToDto() => x =>
        new NotificationDto(x.Id, x.Type, x.Title, x.Message, x.RelatedEntityType, x.RelatedEntityId,
            x.IsRead, x.ReadAtUtc, x.CreatedAtUtc);
}
