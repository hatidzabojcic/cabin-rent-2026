using CabinRent.Model.Announcements;
using CabinRent.Model.Common;

namespace CabinRent.Services.Announcements;

public interface IAnnouncementService
{
    Task<PagedResult<AnnouncementDto>> GetPublishedAsync(PageRequest paging, CancellationToken cancellationToken = default);
    Task<PagedResult<AnnouncementDto>> GetManagementAsync(PageRequest paging, string? search, bool? isActive, CancellationToken cancellationToken = default);
    Task<AnnouncementDto> CreateAsync(SaveAnnouncementRequest request, CancellationToken cancellationToken = default);
    Task<AnnouncementDto?> UpdateAsync(int id, SaveAnnouncementRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
