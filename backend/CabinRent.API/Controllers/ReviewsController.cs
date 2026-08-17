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
    public Task<IReadOnlyCollection<ReviewDto>> Get([FromQuery] int? cabinId, CancellationToken cancellationToken) =>
        service.GetAsync(cabinId, true, cancellationToken);

    [HttpGet("mine")]
    [Authorize(Roles = "Guest")]
    public Task<IReadOnlyCollection<ReviewDto>> GetMine(CancellationToken cancellationToken) =>
        service.GetMineAsync(User.GetUserId(), cancellationToken);

    [HttpGet("management")]
    [Authorize(Roles = "Admin,Owner")]
    public Task<IReadOnlyCollection<ReviewDto>> GetManaged([FromQuery] int? cabinId, [FromQuery] int? rating,
        [FromQuery] bool? approved, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetManagedAsync(User.IsInRole("Admin") ? null : User.GetUserId(), cabinId, rating, approved, search, cancellationToken);

    [HttpPost]
    [Authorize(Roles = "Guest")]
    [ProducesResponseType<ReviewDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<ReviewDto>> Create(CreateReviewRequest request, CancellationToken cancellationToken)
    {
        var review = await service.CreateAsync(request, User.GetUserId(), cancellationToken);
        return StatusCode(StatusCodes.Status201Created, review);
    }

    [HttpPatch("{id:int}/approval")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<ReviewDto>> SetApproval(int id, UpdateReviewApprovalRequest request, CancellationToken cancellationToken)
    {
        var review = await service.SetApprovalAsync(id, request.IsApproved, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return review is null ? NotFound() : Ok(review);
    }
}
