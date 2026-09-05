using CabinRent.Infrastructure.Cabins;
using CabinRent.Infrastructure.Auth;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using CabinRent.Services.Cabins;
using CabinRent.Services.Auth;
using CabinRent.Services.Platform;
using CabinRent.Services.Notifications;
using CabinRent.Infrastructure.Notifications;
using CabinRent.Infrastructure.Recommendations;
using CabinRent.Services.Recommendations;
using CabinRent.Services.Payments;
using CabinRent.Infrastructure.Payments;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using CabinRent.Services.Announcements;
using CabinRent.Infrastructure.Announcements;

namespace CabinRent.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is missing.");

        services.AddDbContext<CabinRentDbContext>(options => options.UseSqlServer(connectionString));
        var jwtSection = configuration.GetSection(JwtOptions.SectionName);
        var jwtOptions = new JwtOptions
        {
            Issuer = jwtSection["Issuer"] ?? string.Empty,
            Audience = jwtSection["Audience"] ?? string.Empty,
            Key = jwtSection["Key"] ?? string.Empty,
            AccessTokenMinutes = int.TryParse(jwtSection["AccessTokenMinutes"], out var accessMinutes) ? accessMinutes : 15,
            RefreshTokenDays = int.TryParse(jwtSection["RefreshTokenDays"], out var refreshDays) ? refreshDays : 7
        };
        if (string.IsNullOrWhiteSpace(jwtOptions.Issuer) || string.IsNullOrWhiteSpace(jwtOptions.Audience) || jwtOptions.Key.Length < 32)
            throw new InvalidOperationException("JWT configuration is missing or invalid.");
        services.AddSingleton<IOptions<JwtOptions>>(Options.Create(jwtOptions));
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<ICabinService, CabinService>();
        services.AddScoped<IAvailabilityBlockService, AvailabilityBlockService>();
        var imageRoot = configuration["ImageStorage:RootPath"] ?? Path.Combine(AppContext.BaseDirectory, "uploads");
        services.AddSingleton<IImageStorage>(new LocalImageStorage(imageRoot));
        services.AddScoped<ICabinImageService, CabinImageService>();
        services.AddMemoryCache();
        services.AddSingleton<ReferenceDataCacheState>();
        services.AddScoped<IPlatformQueryService, PlatformQueryService>();
        services.AddScoped<IReferenceDataService, ReferenceDataService>();
        services.AddScoped<IReservationService, ReservationService>();
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<IFavoriteService, FavoriteService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<IAnnouncementService, AnnouncementService>();
        services.AddSingleton<INotificationEventPublisher, RabbitMqNotificationPublisher>();
        services.AddScoped<IRecommendationService, RecommendationService>();
        var stripeSection = configuration.GetSection(StripeOptions.SectionName);
        services.AddSingleton<IOptions<StripeOptions>>(Options.Create(new StripeOptions
        {
            SecretKey = stripeSection["SecretKey"] ?? string.Empty,
            PublishableKey = stripeSection["PublishableKey"] ?? string.Empty,
            WebhookSecret = stripeSection["WebhookSecret"] ?? string.Empty
        }));
        services.AddSingleton<IPaymentGateway, StripePaymentGateway>();
        services.AddScoped<IPaymentService, PaymentService>();
        return services;
    }
}
