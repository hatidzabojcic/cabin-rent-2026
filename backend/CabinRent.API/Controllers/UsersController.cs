using CabinRent.Model.Users;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public sealed class UsersController(IPlatformQueryService service) : ControllerBase
{
    [HttpGet]
    public Task<IReadOnlyCollection<UserDto>> Get([FromQuery] string? search, [FromQuery] string? role, CancellationToken cancellationToken) =>
        service.GetUsersAsync(search, role, cancellationToken);

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var user = await service.GetUserAsync(id, cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }
}
