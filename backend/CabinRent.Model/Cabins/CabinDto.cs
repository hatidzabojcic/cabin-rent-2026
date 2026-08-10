namespace CabinRent.Model.Cabins;

public sealed record CabinDto(
    int Id,
    string Name,
    string City,
    decimal PricePerNight,
    int MaxGuests,
    double? AverageRating,
    string? CoverImageUrl);
