using System.Net;
using System.Net.Mail;
using CabinRent.Services.Auth;
using Microsoft.Extensions.Options;

namespace CabinRent.Infrastructure.Auth;

public sealed class PasswordResetOptions
{
    public const string SectionName = "PasswordReset";
    public string SmtpHost { get; init; } = "localhost";
    public int SmtpPort { get; init; } = 1025;
    public string FromAddress { get; init; } = "noreply@cabinrent.local";
    public string? UserName { get; init; }
    public string? Password { get; init; }
    public bool EnableSsl { get; init; }
}

public sealed class SmtpPasswordResetDelivery(IOptions<PasswordResetOptions> options) : IPasswordResetDelivery
{
    private readonly PasswordResetOptions settings = options.Value;

    public async Task SendAsync(string email, string token, DateTime expiresAtUtc, CancellationToken cancellationToken = default)
    {
        using var message = new MailMessage(settings.FromAddress, email)
        {
            Subject = "CabinRent – reset lozinke",
            Body = $"Token za reset lozinke:\n\n{token}\n\nToken vrijedi do {expiresAtUtc:dd.MM.yyyy. HH:mm} UTC i može se iskoristiti samo jednom."
        };
        using var client = new SmtpClient(settings.SmtpHost, settings.SmtpPort)
        {
            EnableSsl = settings.EnableSsl,
            Credentials = string.IsNullOrWhiteSpace(settings.UserName)
                ? null
                : new NetworkCredential(settings.UserName, settings.Password)
        };
        await client.SendMailAsync(message, cancellationToken);
    }
}
