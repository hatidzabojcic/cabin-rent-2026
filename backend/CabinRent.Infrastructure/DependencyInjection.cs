using CabinRent.Infrastructure.Cabins;
using CabinRent.Infrastructure.Auth;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using CabinRent.Services.Cabins;
using CabinRent.Services.Auth;
using CabinRent.Services.Platform;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

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
        services.AddScoped<IPlatformQueryService, PlatformQueryService>();
        services.AddScoped<IReservationService, ReservationService>();
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<IFavoriteService, FavoriteService>();
        return services;
    }
}
