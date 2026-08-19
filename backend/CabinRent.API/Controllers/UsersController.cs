using CabinRent.Model.Users;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;
using CabinRent.Model.Common;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public sealed class UsersController(IPlatformQueryService service) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<UserDto>> Get([FromQuery] PageRequest paging, [FromQuery] string? search, [FromQuery] string? role, CancellationToken cancellationToken) =>
        service.GetUsersAsync(paging, search, role, cancellationToken);

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var user = await service.GetUserAsync(id, cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpGet("management")]
    public Task<PagedResult<ManagedUserDto>> GetManaged([FromQuery] PageRequest paging, [FromQuery] string? search, [FromQuery] string? role,
        [FromQuery] bool? isActive, CancellationToken cancellationToken) =>
        service.GetManagedUsersAsync(paging, search, role, isActive, cancellationToken);

    [HttpPatch("{id:int}/status")]
    public async Task<ActionResult<ManagedUserDto>> SetStatus(int id, UpdateUserStatusRequest request, CancellationToken cancellationToken)
    {
        var user = await service.SetUserActiveAsync(id, request.IsActive, User.GetUserId(), cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<ManagedUserDto>> Create(SaveManagedUserRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await service.CreateUserAsync(request, cancellationToken));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ManagedUserDto>> Update(int id, SaveManagedUserRequest request, CancellationToken cancellationToken)
    {
        var user = await service.UpdateUserAsync(id, request, User.GetUserId(), cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken) =>
        await service.DeleteUserAsync(id, User.GetUserId(), cancellationToken) ? NoContent() : NotFound();
}
