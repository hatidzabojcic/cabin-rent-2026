using CabinRent.API.Infrastructure;
using CabinRent.Model.Recommendations;
using CabinRent.Services.Recommendations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Guest")]
public sealed class RecommendationsController(IRecommendationService service) : ControllerBase
{
    [HttpGet]
    public Task<IReadOnlyCollection<RecommendationDto>> Get(
        [FromQuery] int limit = 10, CancellationToken cancellationToken = default) =>
        service.GetAsync(User.GetUserId(), limit, cancellationToken);
}
