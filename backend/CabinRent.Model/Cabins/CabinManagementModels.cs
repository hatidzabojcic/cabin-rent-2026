using System.ComponentModel.DataAnnotations;

namespace CabinRent.Model.Cabins;

public sealed record CabinImageDto(int Id, string Url, string? AltText, int SortOrder, bool IsCover);
public sealed record CabinAmenityDto(int Id, string Name, string? Icon);

public sealed record CabinDetailsDto(
    int Id,
    string Name,
    string Description,
    string Address,
    decimal AreaSquareMeters,
    decimal PricePerNight,
    int MaxAdults,
    int MaxChildren,
    int Bedrooms,
    int Bathrooms,
    double? Latitude,
    double? Longitude,
    bool IsActive,
    int OwnerId,
    string OwnerName,
    int CityId,
    string City,
    int CabinTypeId,
    string CabinType,
    IReadOnlyCollection<CabinImageDto> Images,
    IReadOnlyCollection<CabinAmenityDto> Amenities);

public sealed class SaveCabinRequest
{
    [Required, MaxLength(200)] public required string Name { get; init; }
    [Required, MaxLength(4000)] public required string Description { get; init; }
    [Required, MaxLength(300)] public required string Address { get; init; }
    [Range(typeof(decimal), "1", "10000")] public decimal AreaSquareMeters { get; init; }
    [Range(typeof(decimal), "0.01", "100000")] public decimal PricePerNight { get; init; }
    [Range(1, 100)] public int MaxAdults { get; init; }
    [Range(0, 100)] public int MaxChildren { get; init; }
    [Range(0, 100)] public int Bedrooms { get; init; }
    [Range(1, 100)] public int Bathrooms { get; init; }
    [Range(-90, 90)] public double? Latitude { get; init; }
    [Range(-180, 180)] public double? Longitude { get; init; }
    [Range(1, int.MaxValue)] public int CityId { get; init; }
    [Range(1, int.MaxValue)] public int CabinTypeId { get; init; }
    public int? OwnerId { get; init; }
    public IReadOnlyCollection<int> AmenityIds { get; init; } = [];
    [Url, MaxLength(2000)] public string? CoverImageUrl { get; init; }
}

public sealed class SetCabinActiveRequest
{
    public bool IsActive { get; init; }
}

public sealed class UpdateCabinImageRequest
{
    [MaxLength(300)] public string? AltText { get; init; }
    [Range(0, 1000)] public int SortOrder { get; init; }
    public bool IsCover { get; init; }
}
