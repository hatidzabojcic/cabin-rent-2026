using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace CabinRent.API.Infrastructure;

public static class ClaimsPrincipalExtensions
{
    public static int GetUserId(this ClaimsPrincipal principal) =>
        int.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var id)
            ? id
            : throw new UnauthorizedAccessException("Token ne sadrži validan identitet korisnika.");
}
