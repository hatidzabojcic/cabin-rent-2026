using CabinRent.Model.Reviews;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;
using CabinRent.Model.Common;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class ReviewsController(IReviewService service) : ControllerBase
{
    [HttpGet]
    [AllowAnonymous]
    public Task<PagedResult<PublicReviewDto>> Get([FromQuery] PageRequest paging, [FromQuery] int? cabinId, CancellationToken cancellationToken) =>
        service.GetAsync(paging, cabinId, true, cancellationToken);

    [HttpGet("mine")]
    [Authorize(Roles = "Guest")]
    public Task<PagedResult<ReviewDto>> GetMine([FromQuery] PageRequest paging, CancellationToken cancellationToken) =>
        service.GetMineAsync(paging, User.GetUserId(), cancellationToken);

    [HttpGet("management")]
    [Authorize(Roles = "Admin,Owner")]
    public Task<PagedResult<ReviewDto>> GetManaged([FromQuery] PageRequest paging, [FromQuery] int? cabinId, [FromQuery] int? rating,
        [FromQuery] bool? approved, [FromQuery] string? search, CancellationToken cancellationToken) =>
        service.GetManagedAsync(paging, User.IsInRole("Admin") ? null : User.GetUserId(), cabinId, rating, approved, search, cancellationToken);

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

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Guest")]
    public async Task<ActionResult<ReviewDto>> Update(int id, UpdateReviewRequest request, CancellationToken cancellationToken)
    {
        var review = await service.UpdateAsync(id, request, User.GetUserId(), cancellationToken);
        return review is null ? NotFound() : Ok(review);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin,Guest")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken) =>
        await service.DeleteAsync(id, User.GetUserId(), User.IsInRole("Admin"), cancellationToken) ? NoContent() : NotFound();
}
