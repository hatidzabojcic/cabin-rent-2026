using CabinRent.Model.Announcements;
using CabinRent.Model.Common;
using CabinRent.Services.Announcements;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class AnnouncementsController(IAnnouncementService service) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<AnnouncementDto>> Get([FromQuery] PageRequest paging, CancellationToken cancellationToken) =>
        service.GetPublishedAsync(paging, cancellationToken);

    [HttpGet("management")]
    [Authorize(Roles = "Admin")]
    public Task<PagedResult<AnnouncementDto>> Management([FromQuery] PageRequest paging, [FromQuery] string? search,
        [FromQuery] bool? isActive, CancellationToken cancellationToken) =>
        service.GetManagementAsync(paging, search, isActive, cancellationToken);

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<AnnouncementDto>> Create(SaveAnnouncementRequest request, CancellationToken cancellationToken) =>
        Ok(await service.CreateAsync(request, cancellationToken));

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<AnnouncementDto>> Update(int id, SaveAnnouncementRequest request, CancellationToken cancellationToken)
    {
        var result = await service.UpdateAsync(id, request, cancellationToken);
        return result is null ? NotFound() : Ok(result);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken) =>
        await service.DeleteAsync(id, cancellationToken) ? NoContent() : NotFound();
}
