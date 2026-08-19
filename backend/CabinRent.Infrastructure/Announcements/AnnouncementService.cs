using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Announcements;
using CabinRent.Model.Common;
using CabinRent.Services.Announcements;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Announcements;

public sealed class AnnouncementService(CabinRentDbContext dbContext) : IAnnouncementService
{
    public Task<PagedResult<AnnouncementDto>> GetPublishedAsync(PageRequest paging, CancellationToken cancellationToken = default) =>
        dbContext.Announcements.AsNoTracking()
            .Where(x => x.IsActive && x.PublishedAtUtc <= DateTime.UtcNow)
            .OrderByDescending(x => x.PublishedAtUtc).Select(Projection())
            .ToPagedResultAsync(paging, cancellationToken);

    public Task<PagedResult<AnnouncementDto>> GetManagementAsync(PageRequest paging, string? search, bool? isActive, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Announcements.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(x => x.Title.Contains(search) || x.Content.Contains(search));
        if (isActive.HasValue) query = query.Where(x => x.IsActive == isActive);
        return query.OrderByDescending(x => x.PublishedAtUtc).Select(Projection())
            .ToPagedResultAsync(paging, cancellationToken);
    }

    public async Task<AnnouncementDto> CreateAsync(SaveAnnouncementRequest request, CancellationToken cancellationToken = default)
    {
        var entity = new Announcement { Title = request.Title.Trim(), Content = request.Content.Trim() };
        Apply(entity, request);
        dbContext.Announcements.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(entity);
    }

    public async Task<AnnouncementDto?> UpdateAsync(int id, SaveAnnouncementRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Announcements.FindAsync([id], cancellationToken);
        if (entity is null) return null;
        Apply(entity, request);
        entity.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(entity);
    }

    public async Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await dbContext.Announcements.FindAsync([id], cancellationToken);
        if (entity is null) return false;
        dbContext.Announcements.Remove(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static void Apply(Announcement entity, SaveAnnouncementRequest request)
    {
        entity.Title = request.Title.Trim();
        entity.Content = request.Content.Trim();
        entity.ImageUrl = string.IsNullOrWhiteSpace(request.ImageUrl) ? null : request.ImageUrl.Trim();
        entity.PublishedAtUtc = request.PublishedAtUtc == default ? DateTime.UtcNow : request.PublishedAtUtc.ToUniversalTime();
        entity.IsActive = request.IsActive;
    }

    private static System.Linq.Expressions.Expression<Func<Announcement, AnnouncementDto>> Projection() => x =>
        new AnnouncementDto(x.Id, x.Title, x.Content, x.ImageUrl, x.PublishedAtUtc, x.IsActive, x.CreatedAtUtc);

    private static AnnouncementDto Map(Announcement x) =>
        new(x.Id, x.Title, x.Content, x.ImageUrl, x.PublishedAtUtc, x.IsActive, x.CreatedAtUtc);
}
