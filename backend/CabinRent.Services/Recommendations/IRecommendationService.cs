using CabinRent.Model.Recommendations;

namespace CabinRent.Services.Recommendations;

public interface IRecommendationService
{
    Task<IReadOnlyCollection<RecommendationDto>> GetAsync(
        int userId, int limit, CancellationToken cancellationToken = default);
}
