using CabinRent.Model.Recommendations;
using CabinRent.Model.Common;

namespace CabinRent.Services.Recommendations;

public interface IRecommendationService
{
    Task<PagedResult<RecommendationDto>> GetAsync(
        int userId, PageRequest paging, CancellationToken cancellationToken = default);
}
