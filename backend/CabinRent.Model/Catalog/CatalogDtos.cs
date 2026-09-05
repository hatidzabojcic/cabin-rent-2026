namespace CabinRent.Model.Catalog;

using System.ComponentModel.DataAnnotations;

public sealed record CountryDto(int Id, string Name, string IsoCode);
public sealed record CityDto(int Id, string Name, string? PostalCode, int CountryId, string CountryName);
public sealed record CabinTypeDto(int Id, string Name, string? Description);
public sealed record AmenityDto(int Id, string Name, string? Icon);
public sealed record RoleDto(int Id, string Code, string Name, string? Description);

public sealed class SaveCountryRequest
{
    [Required, MaxLength(100)] public required string Name { get; init; }
    [Required, StringLength(2, MinimumLength = 2)] public required string IsoCode { get; init; }
}

public sealed class SaveCityRequest
{
    [Required, MaxLength(100)] public required string Name { get; init; }
    [MaxLength(20)] public string? PostalCode { get; init; }
    [Range(1, int.MaxValue)] public int CountryId { get; init; }
}

public sealed class SaveCabinTypeRequest
{
    [Required, MaxLength(100)] public required string Name { get; init; }
    [MaxLength(500)] public string? Description { get; init; }
}

public sealed class SaveAmenityRequest
{
    [Required, MaxLength(100)] public required string Name { get; init; }
    [MaxLength(100)] public string? Icon { get; init; }
}

public sealed class CreateRoleRequest
{
    [Required, StringLength(50, MinimumLength = 1)]
    [RegularExpression(@"^[A-Za-z][A-Za-z0-9_-]*$", ErrorMessage = "Kod uloge mora početi slovom i smije sadržavati slova, brojeve, _ i -.")]
    public required string Code { get; init; }
    [Required, MaxLength(50)] public required string Name { get; init; }
    [MaxLength(500)] public string? Description { get; init; }
}

public sealed class UpdateRoleRequest
{
    [Required, MaxLength(50)] public required string Name { get; init; }
    [MaxLength(500)] public string? Description { get; init; }
}
