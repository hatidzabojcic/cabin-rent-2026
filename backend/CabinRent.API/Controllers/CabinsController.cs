using CabinRent.Model.Cabins;
using CabinRent.Model.Common;
using CabinRent.Services.Cabins;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class CabinsController(ICabinService cabinService) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<PagedResult<CabinDto>>(StatusCodes.Status200OK)]
    public Task<PagedResult<CabinDto>> Get([FromQuery] CabinSearchRequest request, CancellationToken cancellationToken) =>
        cabinService.GetAsync(request, cancellationToken);

    [HttpGet("{id:int}")]
    [ProducesResponseType<CabinDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CabinDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.GetByIdAsync(id, cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpGet("manage")]
    [Authorize(Roles = "Admin,Owner")]
    public Task<IReadOnlyCollection<CabinDetailsDto>> GetManaged(CancellationToken cancellationToken) =>
        cabinService.GetManagedAsync(User.GetUserId(), User.IsInRole("Admin"), cancellationToken);

    [HttpGet("manage/{id:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinDetailsDto>> GetManagedById(int id, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.GetManagedByIdAsync(id, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Owner")]
    [ProducesResponseType<CabinDetailsDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<CabinDetailsDto>> Create(SaveCabinRequest request, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.CreateAsync(request, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return CreatedAtAction(nameof(GetManagedById), new { id = cabin.Id }, cabin);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinDetailsDto>> Update(int id, SaveCabinRequest request, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.UpdateAsync(id, request, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }

    [HttpPatch("{id:int}/active")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<CabinDetailsDto>> SetActive(int id, SetCabinActiveRequest request, CancellationToken cancellationToken)
    {
        var cabin = await cabinService.SetActiveAsync(id, request.IsActive, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return cabin is null ? NotFound() : Ok(cabin);
    }
}
