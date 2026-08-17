using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Auth;
using CabinRent.Model.Users;
using CabinRent.Services.Auth;
using CabinRent.Services.Cabins;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace CabinRent.Infrastructure.Auth;

public sealed class AuthService(CabinRentDbContext dbContext, IOptions<JwtOptions> options, IImageStorage imageStorage) : IAuthService
{
    private readonly JwtOptions jwt = options.Value;

    public async Task<AuthResponse?> LoginAsync(LoginRequest request, string? ipAddress, CancellationToken cancellationToken = default)
    {
        var normalized = request.UserName.Trim().ToLowerInvariant();
        var user = await UserQuery().SingleOrDefaultAsync(x => x.UserName == normalized, cancellationToken);
        if (user is null || !user.IsActive || !PasswordHash.Verify(request.Password, user.PasswordHash)) return null;
        return await CreateSessionAsync(user, ipAddress, cancellationToken);
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, string? ipAddress, CancellationToken cancellationToken = default)
    {
        var userName = request.UserName.Trim().ToLowerInvariant();
        var email = request.Email.Trim().ToLowerInvariant();
        if (await dbContext.Users.AnyAsync(x => x.UserName == userName, cancellationToken))
            throw new InvalidOperationException("Korisničko ime je već zauzeto.");
        if (await dbContext.Users.AnyAsync(x => x.Email == email, cancellationToken))
            throw new InvalidOperationException("Email adresa je već registrovana.");

        var guestRole = await dbContext.Roles.SingleAsync(x => x.Name == "Guest", cancellationToken);
        var user = new User
        {
            FirstName = request.FirstName.Trim(), LastName = request.LastName.Trim(), Email = email,
            UserName = userName, PhoneNumber = request.PhoneNumber?.Trim(), PasswordHash = PasswordHash.Create(request.Password),
            UserRoles = [new UserRole { Role = guestRole }]
        };
        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);
        return await CreateSessionAsync(user, ipAddress, cancellationToken);
    }

    public async Task<AuthResponse?> RefreshAsync(string refreshToken, string? ipAddress, CancellationToken cancellationToken = default)
    {
        var hash = HashToken(refreshToken);
        var stored = await dbContext.RefreshTokens.Include(x => x.User).ThenInclude(x => x.UserRoles).ThenInclude(x => x.Role)
            .SingleOrDefaultAsync(x => x.TokenHash == hash, cancellationToken);
        if (stored is null || !stored.User.IsActive) return null;

        if (stored.RevokedAtUtc.HasValue)
        {
            if (stored.ReplacedByTokenHash is not null)
            {
                var activeTokens = await dbContext.RefreshTokens.Where(x => x.UserId == stored.UserId && x.RevokedAtUtc == null && x.ExpiresAtUtc > DateTime.UtcNow).ToListAsync(cancellationToken);
                foreach (var token in activeTokens) { token.RevokedAtUtc = DateTime.UtcNow; token.RevokedByIp = ipAddress; }
                await dbContext.SaveChangesAsync(cancellationToken);
            }
            return null;
        }
        if (stored.ExpiresAtUtc <= DateTime.UtcNow) return null;

        var rawReplacement = GenerateRefreshToken();
        var replacementHash = HashToken(rawReplacement);
        stored.RevokedAtUtc = DateTime.UtcNow;
        stored.RevokedByIp = ipAddress;
        stored.ReplacedByTokenHash = replacementHash;
        dbContext.RefreshTokens.Add(new RefreshToken
        {
            UserId = stored.UserId, TokenHash = replacementHash, ExpiresAtUtc = DateTime.UtcNow.AddDays(jwt.RefreshTokenDays), CreatedByIp = ipAddress
        });
        await dbContext.SaveChangesAsync(cancellationToken);
        return BuildResponse(stored.User, rawReplacement);
    }

    public async Task<bool> LogoutAsync(string refreshToken, string? ipAddress, CancellationToken cancellationToken = default)
    {
        var hash = HashToken(refreshToken);
        var stored = await dbContext.RefreshTokens.SingleOrDefaultAsync(x => x.TokenHash == hash, cancellationToken);
        if (stored is null || stored.RevokedAtUtc.HasValue) return false;
        stored.RevokedAtUtc = DateTime.UtcNow;
        stored.RevokedByIp = ipAddress;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<UserDto?> GetCurrentUserAsync(int userId, CancellationToken cancellationToken = default)
    {
        var user = await UserQuery().SingleOrDefaultAsync(x => x.Id == userId, cancellationToken);
        return user is null ? null : ToDto(user);
    }

    public async Task<UserDto?> UpdateProfileAsync(int userId, UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
            throw new ArgumentException("Ime i prezime su obavezni.");
        var user = await UserQuery().SingleOrDefaultAsync(x => x.Id == userId && x.IsActive, cancellationToken);
        if (user is null) return null;

        var email = request.Email.Trim().ToLowerInvariant();
        if (await dbContext.Users.AnyAsync(x => x.Id != userId && x.Email == email, cancellationToken))
            throw new InvalidOperationException("Email adresa je već registrovana.");

        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = email;
        user.PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim();
        user.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return ToDto(user);
    }

    public async Task<UserDto?> UpdateProfileImageAsync(int userId, Stream content, string extension, CancellationToken cancellationToken = default)
    {
        var user = await UserQuery().SingleOrDefaultAsync(x => x.Id == userId && x.IsActive, cancellationToken);
        if (user is null) return null;

        var previousImageUrl = user.ProfileImageUrl;
        var newImageUrl = await imageStorage.SaveProfileAsync(userId, content, extension, cancellationToken);
        user.ProfileImageUrl = newImageUrl;
        user.UpdatedAtUtc = DateTime.UtcNow;
        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch
        {
            await imageStorage.DeleteAsync(newImageUrl, CancellationToken.None);
            throw;
        }
        if (!string.IsNullOrWhiteSpace(previousImageUrl))
            await imageStorage.DeleteAsync(previousImageUrl, cancellationToken);
        return ToDto(user);
    }

    public async Task<bool> DeactivateProfileAsync(int userId, string? ipAddress, CancellationToken cancellationToken = default)
    {
        var user = await dbContext.Users.Include(x => x.RefreshTokens)
            .SingleOrDefaultAsync(x => x.Id == userId && x.IsActive, cancellationToken);
        if (user is null) return false;

        var now = DateTime.UtcNow;
        user.IsActive = false;
        user.UpdatedAtUtc = now;
        foreach (var token in user.RefreshTokens.Where(x => x.RevokedAtUtc == null))
        {
            token.RevokedAtUtc = now;
            token.RevokedByIp = ipAddress;
        }
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<AuthResponse> CreateSessionAsync(User user, string? ipAddress, CancellationToken cancellationToken)
    {
        var rawRefreshToken = GenerateRefreshToken();
        dbContext.RefreshTokens.Add(new RefreshToken
        {
            UserId = user.Id, TokenHash = HashToken(rawRefreshToken), ExpiresAtUtc = DateTime.UtcNow.AddDays(jwt.RefreshTokenDays), CreatedByIp = ipAddress
        });
        await dbContext.SaveChangesAsync(cancellationToken);
        return BuildResponse(user, rawRefreshToken);
    }

    private AuthResponse BuildResponse(User user, string rawRefreshToken)
    {
        var expires = DateTime.UtcNow.AddMinutes(jwt.AccessTokenMinutes);
        var roles = user.UserRoles.Select(x => x.Role.Name).OrderBy(x => x).ToArray();
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.UniqueName, user.UserName),
            new(JwtRegisteredClaimNames.Email, user.Email),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));
        var credentials = new SigningCredentials(new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)), SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(jwt.Issuer, jwt.Audience, claims, expires: expires, signingCredentials: credentials);
        return new AuthResponse(new JwtSecurityTokenHandler().WriteToken(token), rawRefreshToken, expires, ToDto(user));
    }

    private IQueryable<User> UserQuery() => dbContext.Users.Include(x => x.UserRoles).ThenInclude(x => x.Role);
    private static UserDto ToDto(User user) => new(user.Id, user.FirstName, user.LastName, user.Email, user.UserName, user.PhoneNumber, user.IsActive, user.UserRoles.Select(x => x.Role.Name).OrderBy(x => x).ToArray(), user.ProfileImageUrl);
    private static string GenerateRefreshToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
    private static string HashToken(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));
}
