using CabinRent.Model.Cabins;
using CabinRent.Model.Common;

namespace CabinRent.Services.Cabins;

public interface ICabinService
{
    Task<PagedResult<CabinDto>> GetAsync(CabinSearchRequest request, CancellationToken cancellationToken = default);
    Task<CabinDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
}
