using CabinRent.Model.Reservations;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using CabinRent.API.Infrastructure;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class ReservationsController(IReservationService service) : ControllerBase
{
    [HttpGet]
    public Task<IReadOnlyCollection<ReservationDto>> Get([FromQuery] int? cabinId, [FromQuery] string? status, CancellationToken cancellationToken)
    {
        var userId = User.GetUserId();
        var isAdmin = User.IsInRole("Admin");
        var isOwner = User.IsInRole("Owner");
        return service.GetAsync(isAdmin || isOwner ? null : userId, isAdmin ? null : isOwner ? userId : null, cabinId, status, cancellationToken);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ReservationDto>> GetById(int id, CancellationToken cancellationToken)
    {
        var reservation = await service.GetByIdAsync(id, cancellationToken);
        if (reservation is null) return NotFound();
        var userId = User.GetUserId();
        if (!User.IsInRole("Admin") && reservation.GuestId != userId && reservation.OwnerId != userId) return Forbid();
        return Ok(reservation);
    }

    [HttpPost]
    [Authorize(Roles = "Guest")]
    [ProducesResponseType<ReservationDto>(StatusCodes.Status201Created)]
    public async Task<ActionResult<ReservationDto>> Create(CreateReservationRequest request, CancellationToken cancellationToken)
    {
        var reservation = await service.CreateAsync(request, User.GetUserId(), cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = reservation.Id }, reservation);
    }

    [HttpPatch("{id:int}/status")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<ActionResult<ReservationDto>> UpdateStatus(int id, UpdateReservationStatusRequest request, CancellationToken cancellationToken)
    {
        var reservation = await service.UpdateStatusAsync(id, request, User.GetUserId(), User.IsInRole("Admin"), cancellationToken);
        return reservation is null ? NotFound() : Ok(reservation);
    }
}
