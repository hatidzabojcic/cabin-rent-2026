using CabinRent.Model.Reviews;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class ReviewsController(IReviewService service) : ControllerBase
{
    [HttpGet]
    [AllowAnonymous]
    public Task<IReadOnlyCollection<ReviewDto>> Get([FromQuery] int? cabinId, [FromQuery] bool? approved, CancellationToken cancellationToken) =>
        service.GetAsync(cabinId, approved, cancellationToken);

    [HttpPost]
    [Authorize(Roles = "Guest")]
    [ProducesResponseType<ReviewDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<ReviewDto>> Create(CreateReviewRequest request, CancellationToken cancellationToken)
    {
        var review = await service.CreateAsync(request, User.GetUserId(), cancellationToken);
        return StatusCode(StatusCodes.Status201Created, review);
    }
}
