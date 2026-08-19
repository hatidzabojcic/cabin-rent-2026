using CabinRent.Model.Favorites;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;
using CabinRent.Model.Common;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Guest")]
public sealed class FavoritesController(IFavoriteService service) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<FavoriteDto>> Get([FromQuery] PageRequest paging, CancellationToken cancellationToken) =>
        service.GetAsync(paging, User.GetUserId(), cancellationToken);

    [HttpPost]
    [ProducesResponseType<FavoriteDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<FavoriteDto>> Add(AddFavoriteRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await service.AddAsync(request, User.GetUserId(), cancellationToken));

    [HttpDelete("{cabinId:int}")]
    public async Task<IActionResult> Remove(int cabinId, CancellationToken cancellationToken) =>
        await service.RemoveAsync(User.GetUserId(), cabinId, cancellationToken) ? NoContent() : NotFound();
}
