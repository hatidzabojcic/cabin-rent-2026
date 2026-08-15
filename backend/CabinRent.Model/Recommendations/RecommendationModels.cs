namespace CabinRent.Model.Recommendations;

public sealed record RecommendationDto(
    int CabinId,
    string Name,
    string City,
    decimal PricePerNight,
    int MaxGuests,
    double? AverageRating,
    string? CoverImageUrl,
    double Score,
    string Reason,
    bool IsPersonalized);
