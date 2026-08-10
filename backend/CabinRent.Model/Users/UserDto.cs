namespace CabinRent.Model.Users;

public sealed record UserDto(
    int Id, string FirstName, string LastName, string Email, string UserName,
    string? PhoneNumber, bool IsActive, IReadOnlyCollection<string> Roles);
