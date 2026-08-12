using CabinRent.Model.Cabins;
using CabinRent.Model.Common;

namespace CabinRent.Services.Cabins;

public interface ICabinService
{
    Task<PagedResult<CabinDto>> GetAsync(CabinSearchRequest request, CancellationToken cancellationToken = default);
    Task<CabinDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<CabinDetailsDto>> GetManagedAsync(int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> GetManagedByIdAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto> CreateAsync(SaveCabinRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> UpdateAsync(int id, SaveCabinRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<CabinDetailsDto?> SetActiveAsync(int id, bool isActive, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
}
