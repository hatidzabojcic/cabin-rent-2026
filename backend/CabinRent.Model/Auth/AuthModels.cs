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
    [Required, EmailAddress, MaxLength(320)]
    [RegularExpression(@"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.[A-Za-z]{2,24}$",
        ErrorMessage = "Email mora biti u formatu korisnik@domena.ba.")]
    public required string Email { get; init; }
    [Required, MinLength(3), MaxLength(100)] public required string UserName { get; init; }
    [Required, MinLength(8), MaxLength(200)] public required string Password { get; init; }
    [RegularExpression(@"^\+3876[0-7]\d{6}$", ErrorMessage = "Broj telefona mora biti BiH mobilni broj u formatu +3876XXXXXXX.")]
    [MaxLength(12)] public string? PhoneNumber { get; init; }
}

public sealed class RefreshRequest
{
    [Required] public required string RefreshToken { get; init; }
}

public sealed class ChangePasswordRequest
{
    [Required, MaxLength(200)] public required string CurrentPassword { get; init; }
    [Required, MinLength(8), MaxLength(200)] public required string NewPassword { get; init; }
}

public sealed record AuthResponse(
    string AccessToken, string RefreshToken, DateTime ExpiresAtUtc, UserDto User);
