using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using CabinRent.Services.Payments;

namespace CabinRent.API.Infrastructure;

public sealed class ApiExceptionHandler(IProblemDetailsService problemDetailsService) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var status = exception switch
        {
            ArgumentException => StatusCodes.Status400BadRequest,
            KeyNotFoundException => StatusCodes.Status404NotFound,
            InvalidOperationException => StatusCodes.Status409Conflict,
            UnauthorizedAccessException => StatusCodes.Status403Forbidden,
            PaymentProviderException => StatusCodes.Status502BadGateway,
            PaymentConfigurationException => StatusCodes.Status503ServiceUnavailable,
            InvalidPaymentWebhookException => StatusCodes.Status400BadRequest,
            _ => StatusCodes.Status500InternalServerError
        };
        httpContext.Response.StatusCode = status;
        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            ProblemDetails = new ProblemDetails
            {
                Status = status,
                Title = status == 500 ? "Dogodila se neočekivana greška." : exception.Message
            },
            Exception = exception
        });
    }
}
