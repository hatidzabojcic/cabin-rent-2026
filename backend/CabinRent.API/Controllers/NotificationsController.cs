using CabinRent.API.Infrastructure;
using CabinRent.Model.Notifications;
using CabinRent.Services.Notifications;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using CabinRent.Model.Common;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class NotificationsController(INotificationService service) : ControllerBase
{
    [HttpGet]
    public Task<PagedResult<NotificationDto>> Get([FromQuery] PageRequest paging, [FromQuery] bool? isRead, CancellationToken cancellationToken) =>
        service.GetAsync(paging, User.GetUserId(), isRead, cancellationToken);

    [HttpGet("summary")]
    public async Task<NotificationSummaryDto> Summary(CancellationToken cancellationToken) =>
        new(await service.GetUnreadCountAsync(User.GetUserId(), cancellationToken));

    [HttpPatch("{id:int}/read")]
    public async Task<IActionResult> MarkRead(int id, CancellationToken cancellationToken) =>
        await service.MarkReadAsync(id, User.GetUserId(), cancellationToken) ? NoContent() : NotFound();

    [HttpPatch("read-all")]
    public async Task<NotificationSummaryDto> MarkAllRead(CancellationToken cancellationToken)
    {
        await service.MarkAllReadAsync(User.GetUserId(), cancellationToken);
        return new NotificationSummaryDto(0);
    }
}
