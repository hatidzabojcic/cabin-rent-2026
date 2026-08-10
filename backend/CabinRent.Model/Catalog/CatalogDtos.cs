namespace CabinRent.Model.Catalog;

public sealed record CountryDto(int Id, string Name, string IsoCode);
public sealed record CityDto(int Id, string Name, string? PostalCode, int CountryId, string CountryName);
public sealed record CabinTypeDto(int Id, string Name, string? Description);
public sealed record AmenityDto(int Id, string Name, string? Icon);
public sealed record RoleDto(int Id, string Name, string? Description);
