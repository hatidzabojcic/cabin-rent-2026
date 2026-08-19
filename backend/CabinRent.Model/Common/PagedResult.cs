namespace CabinRent.Model.Common;

public sealed record PagedResult<T>(IReadOnlyCollection<T> Items, int TotalCount, int Page, int PageSize);

public sealed class PageRequest
{
    public int Page { get; init; } = 1;
    public int PageSize { get; init; } = 20;
}
