using System.ComponentModel.DataAnnotations;

namespace CabinRent.Model.Users;

public sealed record UserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles,
    string? ProfileImageUrl = null);

public sealed record ManagedUserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles,
    int CabinCount, int ReservationCount);

public sealed record UpdateUserStatusRequest(bool IsActive);

public sealed class SaveManagedUserRequest
{
    [Required, MaxLength(100)] public required string FirstName { get; init; }
    [Required, MaxLength(100)] public required string LastName { get; init; }
    [Required, EmailAddress, MaxLength(320)] public required string Email { get; init; }
    [Required, MinLength(3), MaxLength(100)] public required string UserName { get; init; }
    [MinLength(8), MaxLength(200)] public string? Password { get; init; }
    [RegularExpression(@"^\+3876[0-7]\d{6}$", ErrorMessage = "Broj telefona mora biti BiH mobilni broj u formatu +3876XXXXXXX.")]
    [MaxLength(12)] public string? PhoneNumber { get; init; }
    [Required] public required string Role { get; init; }
    public bool IsActive { get; init; } = true;
}

public sealed class UpdateProfileRequest
{
    [Required, MaxLength(100)] public required string FirstName { get; init; }
    [Required, MaxLength(100)] public required string LastName { get; init; }
    [Required, EmailAddress, MaxLength(320)]
    [RegularExpression(@"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.[A-Za-z]{2,24}$",
        ErrorMessage = "Email mora biti u formatu korisnik@domena.ba.")]
    public required string Email { get; init; }
    [RegularExpression(@"^\+3876[0-7]\d{6}$", ErrorMessage = "Broj telefona mora biti BiH mobilni broj u formatu +3876XXXXXXX.")]
    [MaxLength(12)] public string? PhoneNumber { get; init; }
}
