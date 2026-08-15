using CabinRent.API.Infrastructure;
using CabinRent.Model.Reports;
using CabinRent.Services.Platform;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,Owner")]
public sealed class ReportsController(IReportService service) : ControllerBase
{
    [HttpGet("annual")]
    public Task<AnnualReportDto> Annual([FromQuery] int year, [FromQuery] int? cabinId, CancellationToken cancellationToken) =>
        service.GetAnnualAsync(year, User.IsInRole("Admin") ? null : User.GetUserId(), cabinId, cancellationToken);

    [HttpGet("top-guests")]
    [Authorize(Roles = "Admin")]
    public Task<TopGuestsReportDto> TopGuests(
        [FromQuery] int year,
        [FromQuery] int? cabinId,
        [FromQuery] int limit = 20,
        CancellationToken cancellationToken = default) =>
        service.GetTopGuestsAsync(year, cabinId, limit, cancellationToken);
}
