using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Cabins;
using CabinRent.Model.Common;
using CabinRent.Services.Cabins;
using CabinRent.Services.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Cabins;

public sealed class CabinService(CabinRentDbContext dbContext) : ICabinService
{
    public async Task<PagedResult<CabinDto>> GetAsync(CabinSearchRequest request, CancellationToken cancellationToken = default)
    {
        var validationError = CabinSearchRules.GetValidationError(
            request,
            DateOnly.FromDateTime(DateTime.UtcNow));
        if (validationError is not null)
            throw new RequestValidationException(validationError);

        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);
        var query = dbContext.Cabins.AsNoTracking().Where(CabinVisibilityRules.PubliclyVisible);

        if (!string.IsNullOrWhiteSpace(request.Search))
            query = query.Where(x =>
                x.Name.Contains(request.Search) ||
                x.Description.Contains(request.Search) ||
                x.City.Name.Contains(request.Search));
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

    public Task<CabinDetailsDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        dbContext.Cabins.AsNoTracking().Where(CabinVisibilityRules.PubliclyVisible).Where(x => x.Id == id)
            .Select(DetailsProjection())
            .SingleOrDefaultAsync(cancellationToken);

    public Task<PagedResult<CabinDetailsDto>> GetManagedAsync(PageRequest paging, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Cabins.AsNoTracking().AsQueryable();
        if (!isAdmin) query = query.Where(x => x.OwnerId == actorId);
        return query.OrderBy(x => x.Name).Select(DetailsProjection())
            .ToPagedResultAsync(paging, cancellationToken);
    }

    public Task<CabinDetailsDto?> GetManagedByIdAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default) =>
        ManagedQuery(id, actorId, isAdmin).AsNoTracking().Select(DetailsProjection()).SingleOrDefaultAsync(cancellationToken);

    public async Task<CabinDetailsDto> CreateAsync(SaveCabinRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var ownerId = isAdmin && request.OwnerId.HasValue ? request.OwnerId.Value : actorId;
        await ValidateReferencesAsync(request, ownerId, cancellationToken);

        var cabin = new Cabin
        {
            Name = request.Name.Trim(), Description = request.Description.Trim(), Address = request.Address.Trim(),
            AreaSquareMeters = request.AreaSquareMeters, PricePerNight = request.PricePerNight,
            MaxAdults = request.MaxAdults, MaxChildren = request.MaxChildren, Bedrooms = request.Bedrooms,
            Bathrooms = request.Bathrooms, Latitude = request.Latitude, Longitude = request.Longitude,
            OwnerId = ownerId, CityId = request.CityId, CabinTypeId = request.CabinTypeId
        };
        ApplyRelations(cabin, request);
        dbContext.Cabins.Add(cabin);
        await dbContext.SaveChangesAsync(cancellationToken);
        return (await GetManagedByIdAsync(cabin.Id, actorId, isAdmin, cancellationToken))!;
    }

    public async Task<CabinDetailsDto?> UpdateAsync(int id, SaveCabinRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var cabin = await ManagedQuery(id, actorId, isAdmin)
            .Include(x => x.Images).Include(x => x.CabinAmenities)
            .SingleOrDefaultAsync(cancellationToken);
        if (cabin is null) return null;

        var ownerId = isAdmin && request.OwnerId.HasValue ? request.OwnerId.Value : cabin.OwnerId;
        await ValidateReferencesAsync(request, ownerId, cancellationToken);
        cabin.Name = request.Name.Trim(); cabin.Description = request.Description.Trim(); cabin.Address = request.Address.Trim();
        cabin.AreaSquareMeters = request.AreaSquareMeters; cabin.PricePerNight = request.PricePerNight;
        cabin.MaxAdults = request.MaxAdults; cabin.MaxChildren = request.MaxChildren; cabin.Bedrooms = request.Bedrooms;
        cabin.Bathrooms = request.Bathrooms; cabin.Latitude = request.Latitude; cabin.Longitude = request.Longitude;
        cabin.OwnerId = ownerId; cabin.CityId = request.CityId; cabin.CabinTypeId = request.CabinTypeId;
        cabin.UpdatedAtUtc = DateTime.UtcNow;
        ApplyRelations(cabin, request);
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetManagedByIdAsync(id, actorId, isAdmin, cancellationToken);
    }

    public async Task<CabinDetailsDto?> SetActiveAsync(int id, bool isActive, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var cabin = await ManagedQuery(id, actorId, isAdmin).SingleOrDefaultAsync(cancellationToken);
        if (cabin is null) return null;
        cabin.IsActive = isActive;
        cabin.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetManagedByIdAsync(id, actorId, isAdmin, cancellationToken);
    }

    public async Task<bool> DeleteAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var cabin = await ManagedQuery(id, actorId, isAdmin).SingleOrDefaultAsync(cancellationToken);
        if (cabin is null) return false;
        cabin.IsActive = false;
        cabin.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private IQueryable<Cabin> ManagedQuery(int id, int actorId, bool isAdmin) =>
        dbContext.Cabins.Where(x => x.Id == id && (isAdmin || x.OwnerId == actorId));

    private async Task ValidateReferencesAsync(SaveCabinRequest request, int ownerId, CancellationToken cancellationToken)
    {
        if (!await dbContext.Users.AnyAsync(x => x.Id == ownerId && x.IsActive && x.UserRoles.Any(r => r.Role.Name == "Owner"), cancellationToken))
            throw new RequestValidationException("Odabrani vlasnik nije validan Owner korisnik.");
        if (!await dbContext.Cities.AnyAsync(x => x.Id == request.CityId, cancellationToken))
            throw new RequestValidationException("Odabrani grad ne postoji.");
        if (!await dbContext.CabinTypes.AnyAsync(x => x.Id == request.CabinTypeId, cancellationToken))
            throw new RequestValidationException("Odabrani tip vikendice ne postoji.");
        var amenityIds = request.AmenityIds.Distinct().ToArray();
        if (amenityIds.Length != await dbContext.Amenities.CountAsync(x => amenityIds.Contains(x.Id), cancellationToken))
            throw new RequestValidationException("Jedna ili više odabranih pogodnosti ne postoje.");
    }

    private static void ApplyRelations(Cabin cabin, SaveCabinRequest request)
    {
        cabin.CabinAmenities.Clear();
        foreach (var amenityId in request.AmenityIds.Distinct())
            cabin.CabinAmenities.Add(new CabinAmenity { AmenityId = amenityId, Cabin = cabin });

        var currentCover = cabin.Images.FirstOrDefault(x => x.IsCover);
        if (string.IsNullOrWhiteSpace(request.CoverImageUrl))
        {
            return;
        }
        else if (currentCover is null)
        {
            cabin.Images.Add(new CabinImage { Url = request.CoverImageUrl.Trim(), AltText = cabin.Name, IsCover = true, SortOrder = 0 });
        }
        else
        {
            currentCover.Url = request.CoverImageUrl.Trim(); currentCover.AltText = cabin.Name; currentCover.UpdatedAtUtc = DateTime.UtcNow;
        }
    }

    private static System.Linq.Expressions.Expression<Func<Cabin, CabinDetailsDto>> DetailsProjection() => x =>
        new CabinDetailsDto(x.Id, x.Name, x.Description, x.Address, x.AreaSquareMeters, x.PricePerNight,
            x.MaxAdults, x.MaxChildren, x.Bedrooms, x.Bathrooms, x.Latitude, x.Longitude, x.IsActive,
            x.OwnerId, x.Owner.FirstName + " " + x.Owner.LastName, x.Owner.IsActive, x.CityId, x.City.Name,
            x.CabinTypeId, x.CabinType.Name,
            x.Images.OrderBy(i => i.SortOrder).Select(i => new CabinImageDto(i.Id, i.Url, i.AltText, i.SortOrder, i.IsCover)).ToList(),
            x.CabinAmenities.OrderBy(a => a.Amenity.Name).Select(a => new CabinAmenityDto(a.AmenityId, a.Amenity.Name, a.Amenity.Icon)).ToList());
}
