using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Catalog;
using CabinRent.Model.Favorites;
using CabinRent.Model.Reservations;
using CabinRent.Model.Reviews;
using CabinRent.Model.Users;
using CabinRent.Services.Platform;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Platform;

public sealed class PlatformQueryService(CabinRentDbContext dbContext) : IPlatformQueryService
{
    public async Task<IReadOnlyCollection<CountryDto>> GetCountriesAsync(CancellationToken cancellationToken = default) =>
        await dbContext.Countries.AsNoTracking().OrderBy(x => x.Name)
            .Select(x => new CountryDto(x.Id, x.Name, x.IsoCode)).ToListAsync(cancellationToken);

    public async Task<IReadOnlyCollection<CityDto>> GetCitiesAsync(int? countryId, string? search, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Cities.AsNoTracking().AsQueryable();
        if (countryId.HasValue) query = query.Where(x => x.CountryId == countryId);
        if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Name.Contains(search));
        return await query.OrderBy(x => x.Name)
            .Select(x => new CityDto(x.Id, x.Name, x.PostalCode, x.CountryId, x.Country.Name)).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<CabinTypeDto>> GetCabinTypesAsync(CancellationToken cancellationToken = default) =>
        await dbContext.CabinTypes.AsNoTracking().OrderBy(x => x.Name)
            .Select(x => new CabinTypeDto(x.Id, x.Name, x.Description)).ToListAsync(cancellationToken);

    public async Task<IReadOnlyCollection<AmenityDto>> GetAmenitiesAsync(CancellationToken cancellationToken = default) =>
        await dbContext.Amenities.AsNoTracking().OrderBy(x => x.Name)
            .Select(x => new AmenityDto(x.Id, x.Name, x.Icon)).ToListAsync(cancellationToken);

    public async Task<IReadOnlyCollection<RoleDto>> GetRolesAsync(CancellationToken cancellationToken = default) =>
        await dbContext.Roles.AsNoTracking().OrderBy(x => x.Name)
            .Select(x => new RoleDto(x.Id, x.Name, x.Description)).ToListAsync(cancellationToken);

    public async Task<IReadOnlyCollection<UserDto>> GetUsersAsync(string? search, string? role, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Users.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(x => x.FirstName.Contains(search) || x.LastName.Contains(search) || x.UserName.Contains(search) || x.Email.Contains(search));
        if (!string.IsNullOrWhiteSpace(role)) query = query.Where(x => x.UserRoles.Any(ur => ur.Role.Name == role));
        return await query.OrderBy(x => x.LastName).ThenBy(x => x.FirstName).Select(UserProjection()).ToListAsync(cancellationToken);
    }

    public Task<UserDto?> GetUserAsync(int id, CancellationToken cancellationToken = default) =>
        dbContext.Users.AsNoTracking().Where(x => x.Id == id).Select(UserProjection()).SingleOrDefaultAsync(cancellationToken);

    private static System.Linq.Expressions.Expression<Func<User, UserDto>> UserProjection() => x =>
        new UserDto(x.Id, x.FirstName, x.LastName, x.Email, x.UserName, x.PhoneNumber, x.IsActive,
            x.UserRoles.Select(ur => ur.Role.Name).OrderBy(name => name).ToList());
}

public sealed class ReservationService(CabinRentDbContext dbContext) : IReservationService
{
    public async Task<IReadOnlyCollection<ReservationDto>> GetAsync(int? guestId, int? ownerId, int? cabinId, string? status, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Reservations.AsNoTracking().AsQueryable();
        if (guestId.HasValue) query = query.Where(x => x.GuestId == guestId);
        if (ownerId.HasValue) query = query.Where(x => x.Cabin.OwnerId == ownerId);
        if (cabinId.HasValue) query = query.Where(x => x.CabinId == cabinId);
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (!Enum.TryParse<ReservationStatus>(status, true, out var parsed))
                throw new ArgumentException("Nepoznat status rezervacije.");
            query = query.Where(x => x.Status == parsed);
        }
        return await query.OrderByDescending(x => x.CheckIn).Select(Projection()).ToListAsync(cancellationToken);
    }

    public Task<ReservationDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        dbContext.Reservations.AsNoTracking().Where(x => x.Id == id).Select(Projection()).SingleOrDefaultAsync(cancellationToken);

    public async Task<ReservationDto> CreateAsync(CreateReservationRequest request, int guestId, CancellationToken cancellationToken = default)
    {
        if (request.CheckOut <= request.CheckIn) throw new ArgumentException("Check-out mora biti nakon check-in datuma.");
        var cabin = await dbContext.Cabins.SingleOrDefaultAsync(x => x.Id == request.CabinId && x.IsActive, cancellationToken)
            ?? throw new KeyNotFoundException("Vikendica nije pronađena.");
        if (!await dbContext.Users.AnyAsync(x => x.Id == guestId && x.IsActive, cancellationToken))
            throw new KeyNotFoundException("Gost nije pronađen.");
        if (request.Adults + request.Children > cabin.MaxAdults + cabin.MaxChildren)
            throw new ArgumentException("Broj gostiju prelazi kapacitet vikendice.");

        var overlaps = await dbContext.Reservations.AnyAsync(x => x.CabinId == request.CabinId &&
            x.Status != ReservationStatus.Cancelled && x.Status != ReservationStatus.Rejected &&
            request.CheckIn < x.CheckOut && request.CheckOut > x.CheckIn, cancellationToken);
        var blocked = await dbContext.AvailabilityBlocks.AnyAsync(x => x.CabinId == request.CabinId &&
            request.CheckIn < x.To && request.CheckOut > x.From, cancellationToken);
        if (overlaps || blocked) throw new InvalidOperationException("Vikendica nije dostupna u odabranom terminu.");

        var nights = request.CheckOut.DayNumber - request.CheckIn.DayNumber;
        var reservation = new Reservation
        {
            CabinId = request.CabinId, GuestId = guestId, CheckIn = request.CheckIn, CheckOut = request.CheckOut,
            Adults = request.Adults, Children = request.Children, SpecialRequests = request.SpecialRequests,
            PricePerNight = cabin.PricePerNight, TotalPrice = cabin.PricePerNight * nights,
            Payment = new Payment { Amount = cabin.PricePerNight * nights, Currency = "BAM", Provider = "Pending", Status = PaymentStatus.Pending }
        };
        dbContext.Reservations.Add(reservation);
        await dbContext.SaveChangesAsync(cancellationToken);
        return (await GetByIdAsync(reservation.Id, cancellationToken))!;
    }

    public async Task<ReservationDto?> UpdateStatusAsync(int id, UpdateReservationStatusRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        if (!Enum.TryParse<ReservationStatus>(request.Status, true, out var status))
            throw new ArgumentException("Nepoznat status rezervacije.");
        var reservation = await dbContext.Reservations.Include(x => x.Cabin).SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (reservation is null) return null;
        if (!isAdmin && reservation.Cabin.OwnerId != actorId) throw new UnauthorizedAccessException("Nemate pristup ovoj rezervaciji.");
        if (reservation.Status == status) return await GetByIdAsync(id, cancellationToken);
        if (!ReservationStatusRules.CanTransition(reservation.Status, status))
            throw new InvalidOperationException($"Status rezervacije nije moguće promijeniti iz {reservation.Status} u {status}.");
        reservation.Status = status;
        reservation.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetByIdAsync(id, cancellationToken);
    }

    private static System.Linq.Expressions.Expression<Func<Reservation, ReservationDto>> Projection() => x =>
        new ReservationDto(x.Id, x.ConfirmationCode, x.CabinId, x.Cabin.Name, x.Cabin.OwnerId, x.GuestId,
            x.Guest.FirstName + " " + x.Guest.LastName, x.Guest.Email, x.Guest.PhoneNumber,
            x.CheckIn, x.CheckOut, x.Adults, x.Children, x.PricePerNight, x.TotalPrice,
            x.Status.ToString(), x.SpecialRequests, x.Payment == null ? null : x.Payment.Status.ToString(), x.CreatedAtUtc);
}

public sealed class ReviewService(CabinRentDbContext dbContext) : IReviewService
{
    public async Task<IReadOnlyCollection<ReviewDto>> GetAsync(int? cabinId, bool? approved, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Reviews.AsNoTracking().AsQueryable();
        if (cabinId.HasValue) query = query.Where(x => x.CabinId == cabinId);
        if (approved.HasValue) query = query.Where(x => x.IsApproved == approved);
        return await query.OrderByDescending(x => x.CreatedAtUtc).Select(Projection()).ToListAsync(cancellationToken);
    }

    public async Task<ReviewDto> CreateAsync(CreateReviewRequest request, int guestId, CancellationToken cancellationToken = default)
    {
        var reservation = await dbContext.Reservations.Include(x => x.Review).SingleOrDefaultAsync(x => x.Id == request.ReservationId, cancellationToken)
            ?? throw new KeyNotFoundException("Rezervacija nije pronađena.");
        if (reservation.Status != ReservationStatus.Completed) throw new InvalidOperationException("Recenzija je dozvoljena tek nakon završenog boravka.");
        if (reservation.GuestId != guestId) throw new UnauthorizedAccessException("Nemate pristup ovoj rezervaciji.");
        if (reservation.Review is not null) throw new InvalidOperationException("Rezervacija već ima recenziju.");
        var review = new Review { Reservation = reservation, CabinId = reservation.CabinId, GuestId = reservation.GuestId, Rating = request.Rating, Comment = request.Comment, IsApproved = false };
        dbContext.Reviews.Add(review);
        await dbContext.SaveChangesAsync(cancellationToken);
        return await dbContext.Reviews.AsNoTracking().Where(x => x.Id == review.Id).Select(Projection()).SingleAsync(cancellationToken);
    }

    private static System.Linq.Expressions.Expression<Func<Review, ReviewDto>> Projection() => x =>
        new ReviewDto(x.Id, x.ReservationId, x.CabinId, x.Cabin.Name, x.GuestId,
            x.Guest.FirstName + " " + x.Guest.LastName, x.Rating, x.Comment, x.IsApproved, x.CreatedAtUtc);
}

public sealed class FavoriteService(CabinRentDbContext dbContext) : IFavoriteService
{
    public async Task<IReadOnlyCollection<FavoriteDto>> GetAsync(int userId, CancellationToken cancellationToken = default) =>
        await dbContext.Favorites.AsNoTracking().Where(x => x.UserId == userId).OrderByDescending(x => x.CreatedAtUtc)
            .Select(x => new FavoriteDto(x.UserId, x.CabinId, x.Cabin.Name, x.Cabin.PricePerNight, x.CreatedAtUtc)).ToListAsync(cancellationToken);

    public async Task<FavoriteDto> AddAsync(AddFavoriteRequest request, int userId, CancellationToken cancellationToken = default)
    {
        if (!await dbContext.Users.AnyAsync(x => x.Id == userId, cancellationToken) || !await dbContext.Cabins.AnyAsync(x => x.Id == request.CabinId, cancellationToken))
            throw new KeyNotFoundException("Korisnik ili vikendica nije pronađena.");
        var existing = await dbContext.Favorites.FindAsync([userId, request.CabinId], cancellationToken);
        if (existing is null)
        {
            existing = new Favorite { UserId = userId, CabinId = request.CabinId };
            dbContext.Favorites.Add(existing);
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        return await dbContext.Favorites.AsNoTracking().Where(x => x.UserId == userId && x.CabinId == request.CabinId)
            .Select(x => new FavoriteDto(x.UserId, x.CabinId, x.Cabin.Name, x.Cabin.PricePerNight, x.CreatedAtUtc)).SingleAsync(cancellationToken);
    }

    public async Task<bool> RemoveAsync(int userId, int cabinId, CancellationToken cancellationToken = default)
    {
        var favorite = await dbContext.Favorites.FindAsync([userId, cabinId], cancellationToken);
        if (favorite is null) return false;
        dbContext.Favorites.Remove(favorite);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }
}
