using System.IdentityModel.Tokens.Jwt;
using CabinRent.Model.Auth;
using CabinRent.Model.Users;
using CabinRent.Services.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using CabinRent.API.Infrastructure;

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

    [Authorize(Roles = "Guest")]
    [HttpDelete("me")]
    public async Task<IActionResult> DeactivateMe(CancellationToken cancellationToken) =>
        await authService.DeactivateProfileAsync(User.GetUserId(), ClientIp(), cancellationToken) ? NoContent() : NotFound();

    private string? ClientIp() => HttpContext.Connection.RemoteIpAddress?.ToString();
}
