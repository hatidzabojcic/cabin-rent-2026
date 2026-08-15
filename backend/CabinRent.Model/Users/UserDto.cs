using System.ComponentModel.DataAnnotations;

namespace CabinRent.Model.Users;

public sealed record UserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles);

public sealed record ManagedUserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles,
    int CabinCount, int ReservationCount);

public sealed record UpdateUserStatusRequest(bool IsActive);

public sealed class UpdateProfileRequest
{
    [Required, MaxLength(100)] public required string FirstName { get; init; }
    [Required, MaxLength(100)] public required string LastName { get; init; }
    [Required, EmailAddress, MaxLength(320)] public required string Email { get; init; }
    [MaxLength(50)] public string? PhoneNumber { get; init; }
}
