namespace CabinRent.Model.Favorites;

public sealed record FavoriteDto(int UserId, int CabinId, string CabinName, decimal PricePerNight, DateTime CreatedAtUtc);
public sealed record AddFavoriteRequest(int CabinId);
