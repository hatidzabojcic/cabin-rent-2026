namespace CabinRent.Model.Users;

public sealed record UserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles);

public sealed record ManagedUserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles,
    int CabinCount, int ReservationCount);

public sealed record UpdateUserStatusRequest(bool IsActive);
