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

    [HttpPost("webhook")]
    [AllowAnonymous]
    [ProducesResponseType<PaymentWebhookResultDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PaymentWebhookResultDto>> Webhook(CancellationToken cancellationToken)
    {
        using var reader = new StreamReader(Request.Body);
        var payload = await reader.ReadToEndAsync(cancellationToken);
        var signature = Request.Headers["Stripe-Signature"].ToString();
        var result = await paymentService.ProcessWebhookAsync(payload, signature, cancellationToken);
        return Ok(result);
    }
}
