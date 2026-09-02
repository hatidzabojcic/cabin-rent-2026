using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using CabinRent.Services.Payments;
using CabinRent.Services.Exceptions;

namespace CabinRent.API.Infrastructure;

public sealed class ApiExceptionHandler(
    ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var status = exception switch
        {
            RequestValidationException => StatusCodes.Status400BadRequest,
            ResourceNotFoundException => StatusCodes.Status404NotFound,
            BusinessRuleException => StatusCodes.Status409Conflict,
            ForbiddenOperationException => StatusCodes.Status403Forbidden,
            ArgumentException => StatusCodes.Status400BadRequest,
            KeyNotFoundException => StatusCodes.Status404NotFound,
            InvalidOperationException => StatusCodes.Status409Conflict,
            UnauthorizedAccessException => StatusCodes.Status403Forbidden,
            PaymentProviderException => StatusCodes.Status502BadGateway,
            PaymentConfigurationException => StatusCodes.Status503ServiceUnavailable,
            InvalidPaymentWebhookException => StatusCodes.Status400BadRequest,
            _ => StatusCodes.Status500InternalServerError
        };
        if (status >= StatusCodes.Status500InternalServerError)
            logger.LogError(exception, "Unhandled API error for {Method} {Path}. TraceId: {TraceId}",
                httpContext.Request.Method, httpContext.Request.Path, httpContext.TraceIdentifier);
        else
            logger.LogWarning(exception, "API request rejected with status {Status} for {Method} {Path}. TraceId: {TraceId}",
                status, httpContext.Request.Method, httpContext.Request.Path, httpContext.TraceIdentifier);
        var problemDetails = new ProblemDetails
        {
            Status = status,
            Title = status switch
            {
                StatusCodes.Status400BadRequest => "Neispravan zahtjev",
                StatusCodes.Status403Forbidden => "Pristup nije dozvoljen",
                StatusCodes.Status404NotFound => "Podatak nije pronađen",
                StatusCodes.Status409Conflict => "Zahtjev nije moguće izvršiti",
                StatusCodes.Status500InternalServerError =>
                    "Dogodila se neočekivana greška.",
                _ => "Zahtjev nije uspješno obrađen"
            },
            Detail = status == StatusCodes.Status500InternalServerError
                ? null
                : exception.Message
        };

        problemDetails.Extensions["traceId"] = httpContext.TraceIdentifier;

        httpContext.Response.StatusCode = status;
        httpContext.Response.ContentType = "application/problem+json";
        await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);
        return true;
    }
}
