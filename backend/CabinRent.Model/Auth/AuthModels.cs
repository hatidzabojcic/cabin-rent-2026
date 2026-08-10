using System.ComponentModel.DataAnnotations;
using CabinRent.Model.Users;

namespace CabinRent.Model.Auth;

public sealed class LoginRequest
{
    [Required, MaxLength(100)] public required string UserName { get; init; }
    [Required, MaxLength(200)] public required string Password { get; init; }
}

public sealed class RegisterRequest
{
    [Required, MaxLength(100)] public required string FirstName { get; init; }
    [Required, MaxLength(100)] public required string LastName { get; init; }
    [Required, EmailAddress, MaxLength(320)] public required string Email { get; init; }
    [Required, MinLength(3), MaxLength(100)] public required string UserName { get; init; }
    [Required, MinLength(8), MaxLength(200)] public required string Password { get; init; }
    [MaxLength(50)] public string? PhoneNumber { get; init; }
}

public sealed class RefreshRequest
{
    [Required] public required string RefreshToken { get; init; }
}

public sealed record AuthResponse(
    string AccessToken, string RefreshToken, DateTime ExpiresAtUtc, UserDto User);
