using CabinRent.Model.Users;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;

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

    [HttpGet("management")]
    public Task<IReadOnlyCollection<ManagedUserDto>> GetManaged([FromQuery] string? search, [FromQuery] string? role,
        [FromQuery] bool? isActive, CancellationToken cancellationToken) =>
        service.GetManagedUsersAsync(search, role, isActive, cancellationToken);

    [HttpPatch("{id:int}/status")]
    public async Task<ActionResult<ManagedUserDto>> SetStatus(int id, UpdateUserStatusRequest request, CancellationToken cancellationToken)
    {
        var user = await service.SetUserActiveAsync(id, request.IsActive, User.GetUserId(), cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }
}
