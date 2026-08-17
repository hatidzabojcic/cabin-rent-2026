using CabinRent.API.Infrastructure;
using CabinRent.Model.Payments;
using CabinRent.Services.Payments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Guest")]
public sealed class PaymentsController(IPaymentService paymentService) : ControllerBase
{
    [HttpPost("reservations/{reservationId:int}/intent")]
    [ProducesResponseType<PaymentIntentDto>(StatusCodes.Status200OK)]
    public async Task<ActionResult<PaymentIntentDto>> CreateIntent(int reservationId, CancellationToken cancellationToken)
    {
        var intent = await paymentService.CreateIntentAsync(reservationId, User.GetUserId(), cancellationToken);
        return Ok(intent);
    }
}
