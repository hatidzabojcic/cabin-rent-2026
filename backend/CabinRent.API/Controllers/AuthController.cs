using System.IdentityModel.Tokens.Jwt;
using CabinRent.Model.Auth;
using CabinRent.Model.Users;
using CabinRent.Services.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using CabinRent.API.Infrastructure;
using CabinRent.Infrastructure.Cabins;

namespace CabinRent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController(IAuthService authService) : ControllerBase
{
    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var response = await authService.LoginAsync(request, ClientIp(), cancellationToken);
        return response is null ? Unauthorized(new ProblemDetails { Status = 401, Title = "Pogrešno korisničko ime ili lozinka." }) : Ok(response);
    }

    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("register")]
    [ProducesResponseType<AuthResponse>(StatusCodes.Status201Created)]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request, CancellationToken cancellationToken) =>
        StatusCode(StatusCodes.Status201Created, await authService.RegisterAsync(request, ClientIp(), cancellationToken));

    [AllowAnonymous]
    [EnableRateLimiting("auth")]
    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh(RefreshRequest request, CancellationToken cancellationToken)
    {
        var response = await authService.RefreshAsync(request.RefreshToken, ClientIp(), cancellationToken);
        return response is null ? Unauthorized(new ProblemDetails { Status = 401, Title = "Refresh token nije validan ili je istekao." }) : Ok(response);
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(RefreshRequest request, CancellationToken cancellationToken) =>
        await authService.LogoutAsync(request.RefreshToken, ClientIp(), cancellationToken) ? NoContent() : NotFound();

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> Me(CancellationToken cancellationToken)
    {
        var claim = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        if (!int.TryParse(claim, out var userId)) return Unauthorized();
        var user = await authService.GetCurrentUserAsync(userId, cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }

    [Authorize]
    [HttpPut("me")]
    public async Task<ActionResult<UserDto>> UpdateMe(UpdateProfileRequest request, CancellationToken cancellationToken)
    {
        var user = await authService.UpdateProfileAsync(User.GetUserId(), request, cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }

    [Authorize]
    [HttpPost("me/image")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<ActionResult<UserDto>> UpdateProfileImage(IFormFile file, CancellationToken cancellationToken)
    {
        if (file.Length == 0) return BadRequest("Odaberite profilnu sliku.");
        if (file.Length > 5 * 1024 * 1024) return BadRequest("Profilna slika ne smije biti veća od 5 MB.");
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!CabinImageRules.IsSupported(extension, file.ContentType))
            return BadRequest("Dozvoljeni formati su JPG, PNG i WebP.");
        await using var stream = file.OpenReadStream();
        if (!await CabinImageRules.HasValidSignatureAsync(stream, extension, cancellationToken))
            return BadRequest("Sadrzaj datoteke ne odgovara odabranom formatu slike.");
        var user = await authService.UpdateProfileImageAsync(User.GetUserId(), stream, extension, cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }

    [Authorize(Roles = "Guest")]
    [HttpDelete("me")]
    public async Task<IActionResult> DeactivateMe(CancellationToken cancellationToken) =>
        await authService.DeactivateProfileAsync(User.GetUserId(), ClientIp(), cancellationToken) ? NoContent() : NotFound();

    [Authorize]
    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordRequest request, CancellationToken cancellationToken) =>
        await authService.ChangePasswordAsync(User.GetUserId(), request, cancellationToken) ? NoContent() : NotFound();

    private string? ClientIp() => HttpContext.Connection.RemoteIpAddress?.ToString();
}
