using CabinRent.Model.Cabins;
using CabinRent.Model.Common;

namespace CabinRent.Services.Cabins;

public interface ICabinService
{
    Task<PagedResult<CabinDto>> GetAsync(CabinSearchRequest request, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<PagedResult<CabinDetailsDto>> GetManagedAsync(PageRequest paging, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> GetManagedByIdAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto> CreateAsync(SaveCabinRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> UpdateAsync(int id, SaveCabinRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> SetActiveAsync(int id, bool isActive, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
}

public interface IImageStorage
{
    Task<string> SaveAsync(int cabinId, Stream content, string extension, CancellationToken cancellationToken = default);
    Task<string> SaveProfileAsync(int userId, Stream content, string extension, CancellationToken cancellationToken = default);
    Task DeleteAsync(string url, CancellationToken cancellationToken = default);
}

public interface ICabinImageService
{
    Task<CabinImageDto> AddAsync(int cabinId, Stream content, string extension, string? altText, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinImageDto?> UpdateAsync(int cabinId, int imageId, UpdateCabinImageRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(int cabinId, int imageId, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
}
