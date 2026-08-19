using CabinRent.API.Infrastructure;
using CabinRent.Model.Recommendations;
using CabinRent.Services.Recommendations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CabinRent.Model.Common;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Guest")]
public sealed class RecommendationsController(IRecommendationService service) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<RecommendationDto>> Get(
        [FromQuery] PageRequest paging, CancellationToken cancellationToken = default) =>
        service.GetAsync(User.GetUserId(), paging, cancellationToken);
}
