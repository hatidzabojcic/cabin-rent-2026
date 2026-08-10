using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Cabins;
using CabinRent.Model.Common;
using CabinRent.Services.Cabins;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Cabins;

public sealed class CabinService(CabinRentDbContext dbContext) : ICabinService
{
    public async Task<PagedResult<CabinDto>> GetAsync(CabinSearchRequest request, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);
        var query = dbContext.Cabins.AsNoTracking().Where(x => x.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Search))
            query = query.Where(x => x.Name.Contains(request.Search) || x.Description.Contains(request.Search));
        if (request.CityId.HasValue)
            query = query.Where(x => x.CityId == request.CityId);
        if (request.Guests.HasValue)
            query = query.Where(x => x.MaxAdults + x.MaxChildren >= request.Guests);
        if (request.MinPrice.HasValue)
            query = query.Where(x => x.PricePerNight >= request.MinPrice);
        if (request.MaxPrice.HasValue)
            query = query.Where(x => x.PricePerNight <= request.MaxPrice);
        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            query = query.Where(c => !c.Reservations.Any(r =>
                r.Status != ReservationStatus.Cancelled && r.Status != ReservationStatus.Rejected &&
                request.CheckIn < r.CheckOut && request.CheckOut > r.CheckIn));
            query = query.Where(c => !dbContext.AvailabilityBlocks.Any(b =>
                b.CabinId == c.Id && request.CheckIn < b.To && request.CheckOut > b.From));
        }

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query.OrderBy(x => x.Name)
            .Skip((page - 1) * pageSize).Take(pageSize)
            .Select(x => new CabinDto(
                x.Id, x.Name, x.City.Name, x.PricePerNight, x.MaxAdults + x.MaxChildren,
                dbContext.Reviews.Where(r => r.CabinId == x.Id && r.IsApproved).Select(r => (double?)r.Rating).Average(),
                x.Images.Where(i => i.IsCover).Select(i => i.Url).FirstOrDefault()))
            .ToListAsync(cancellationToken);

        return new PagedResult<CabinDto>(items, totalCount, page, pageSize);
    }

    public Task<CabinDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        dbContext.Cabins.AsNoTracking().Where(x => x.Id == id && x.IsActive)
            .Select(x => new CabinDto(
                x.Id, x.Name, x.City.Name, x.PricePerNight, x.MaxAdults + x.MaxChildren,
                dbContext.Reviews.Where(r => r.CabinId == x.Id && r.IsApproved).Select(r => (double?)r.Rating).Average(),
                x.Images.Where(i => i.IsCover).Select(i => i.Url).FirstOrDefault()))
            .SingleOrDefaultAsync(cancellationToken);
}
