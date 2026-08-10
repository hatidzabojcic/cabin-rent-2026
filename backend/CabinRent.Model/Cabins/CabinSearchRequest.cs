namespace CabinRent.Model.Cabins;

public sealed class CabinSearchRequest
{
    public string? Search { get; init; }
    public int? CityId { get; init; }
    public DateOnly? CheckIn { get; init; }
    public DateOnly? CheckOut { get; init; }
    public int? Guests { get; init; }
    public decimal? MinPrice { get; init; }
    public decimal? MaxPrice { get; init; }
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
