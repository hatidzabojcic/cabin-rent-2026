using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Notifications;
using CabinRent.Model.Catalog;
using CabinRent.Model.Favorites;
using CabinRent.Model.Reservations;
using CabinRent.Model.Reviews;
using CabinRent.Model.Users;
using CabinRent.Services.Platform;
using CabinRent.Infrastructure.Cabins;
using CabinRent.Model.Notifications;
using Microsoft.EntityFrameworkCore;
using CabinRent.Model.Common;
using Microsoft.Extensions.Caching.Memory;

namespace CabinRent.Infrastructure.Platform;

public sealed class PlatformQueryService(
    CabinRentDbContext dbContext,
    IMemoryCache memoryCache,
    ReferenceDataCacheState cacheState) : IPlatformQueryService
{
    public async Task<PagedResult<CountryDto>> GetCountriesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default)
    {
        return (await memoryCache.GetOrCreateAsync(CacheKey("countries", paging, search), async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var query = dbContext.Countries.AsNoTracking().AsQueryable();
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Name.Contains(search) || x.IsoCode.Contains(search));
            return await query.OrderBy(x => x.Name).Select(x => new CountryDto(x.Id, x.Name, x.IsoCode))
                .ToPagedResultAsync(paging, cancellationToken);
        }))!;
    }

    public async Task<PagedResult<CityDto>> GetCitiesAsync(PageRequest paging, int? countryId, string? search, CancellationToken cancellationToken = default)
    {
        return (await memoryCache.GetOrCreateAsync($"{CacheKey("cities", paging, search)}:{countryId}", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var query = dbContext.Cities.AsNoTracking().AsQueryable();
            if (countryId.HasValue) query = query.Where(x => x.CountryId == countryId);
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Name.Contains(search));
            return await query.OrderBy(x => x.Name)
                .Select(x => new CityDto(x.Id, x.Name, x.PostalCode, x.CountryId, x.Country.Name))
                .ToPagedResultAsync(paging, cancellationToken);
        }))!;
    }

    public async Task<PagedResult<CabinTypeDto>> GetCabinTypesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default)
    {
        return (await memoryCache.GetOrCreateAsync(CacheKey("cabin-types", paging, search), async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var query = dbContext.CabinTypes.AsNoTracking().AsQueryable();
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Name.Contains(search));
            return await query.OrderBy(x => x.Name).Select(x => new CabinTypeDto(x.Id, x.Name, x.Description))
                .ToPagedResultAsync(paging, cancellationToken);
        }))!;
    }

    public async Task<PagedResult<AmenityDto>> GetAmenitiesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default)
    {
        return (await memoryCache.GetOrCreateAsync(CacheKey("amenities", paging, search), async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var query = dbContext.Amenities.AsNoTracking().AsQueryable();
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Name.Contains(search));
            return await query.OrderBy(x => x.Name).Select(x => new AmenityDto(x.Id, x.Name, x.Icon))
                .ToPagedResultAsync(paging, cancellationToken);
        }))!;
    }

    public async Task<PagedResult<RoleDto>> GetRolesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default)
    {
        return (await memoryCache.GetOrCreateAsync(CacheKey("roles", paging, search), async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10);
            var query = dbContext.Roles.AsNoTracking().AsQueryable();
            if (!string.IsNullOrWhiteSpace(search)) query = query.Where(x => x.Name.Contains(search));
            return await query.OrderBy(x => x.Name).Select(x => new RoleDto(x.Id, x.Name, x.Description))
                .ToPagedResultAsync(paging, cancellationToken);
        }))!;
    }

    private string CacheKey(string resource, PageRequest paging, string? search) =>
        $"reference:{cacheState.Version}:{resource}:{paging.Page}:{paging.PageSize}:{search?.Trim().ToLowerInvariant()}";

    public Task<PagedResult<UserDto>> GetUsersAsync(PageRequest paging, string? search, string? role, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Users.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(x => x.FirstName.Contains(search) || x.LastName.Contains(search) || x.UserName.Contains(search) || x.Email.Contains(search));
        if (!string.IsNullOrWhiteSpace(role)) query = query.Where(x => x.UserRoles.Any(ur => ur.Role.Name == role));
        return query.OrderBy(x => x.LastName).ThenBy(x => x.FirstName).Select(UserProjection())
            .ToPagedResultAsync(paging, cancellationToken);
    }

    public Task<UserDto?> GetUserAsync(int id, CancellationToken cancellationToken = default) =>
        dbContext.Users.AsNoTracking().Where(x => x.Id == id).Select(UserProjection()).SingleOrDefaultAsync(cancellationToken);

    public Task<PagedResult<ManagedUserDto>> GetManagedUsersAsync(PageRequest paging, string? search, string? role, bool? isActive, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Users.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(x => x.FirstName.Contains(term) || x.LastName.Contains(term) || x.UserName.Contains(term) || x.Email.Contains(term));
        }
        if (!string.IsNullOrWhiteSpace(role)) query = query.Where(x => x.UserRoles.Any(ur => ur.Role.Name == role));
        if (isActive.HasValue) query = query.Where(x => x.IsActive == isActive.Value);
        return query.OrderBy(x => x.LastName).ThenBy(x => x.FirstName)
            .Select(ManagedUserProjection()).ToPagedResultAsync(paging, cancellationToken);
    }

    public async Task<ManagedUserDto?> SetUserActiveAsync(int id, bool isActive, int actorId, CancellationToken cancellationToken = default)
    {
        if (!UserManagementRules.CanChangeStatus(id, isActive, actorId))
            throw new BusinessRuleException("Ne možete deaktivirati vlastiti administratorski nalog.");

        var user = await dbContext.Users.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (user is null) return null;
        user.IsActive = isActive;
        user.UpdatedAtUtc = DateTime.UtcNow;
        if (!isActive)
        {
            var refreshTokens = await dbContext.RefreshTokens.Where(x => x.UserId == id && x.RevokedAtUtc == null).ToListAsync(cancellationToken);
            foreach (var token in refreshTokens) token.RevokedAtUtc = DateTime.UtcNow;
        }
        await dbContext.SaveChangesAsync(cancellationToken);
        return await dbContext.Users.AsNoTracking().Where(x => x.Id == id).Select(ManagedUserProjection()).SingleAsync(cancellationToken);
    }

    public async Task<ManagedUserDto> CreateUserAsync(SaveManagedUserRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.Password))
            throw new RequestValidationException("Lozinka je obavezna prilikom kreiranja korisnika.");
        var email = request.Email.Trim().ToLowerInvariant();
        var userName = request.UserName.Trim();
        if (await dbContext.Users.AnyAsync(x => x.Email == email || x.UserName == userName, cancellationToken))
            throw new BusinessRuleException("Email adresa ili korisnicko ime vec postoji.");
        var role = await dbContext.Roles.SingleOrDefaultAsync(x => x.Name == request.Role, cancellationToken)
            ?? throw new ResourceNotFoundException("Uloga nije pronadjena.");
        var user = new User
        {
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            Email = email,
            UserName = userName,
            PasswordHash = PasswordHash.Create(request.Password),
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
            IsActive = request.IsActive,
            UserRoles = [new UserRole { Role = role }]
        };
        dbContext.Users.Add(user);
        await dbContext.SaveChangesAsync(cancellationToken);
        return await dbContext.Users.AsNoTracking().Where(x => x.Id == user.Id)
            .Select(ManagedUserProjection()).SingleAsync(cancellationToken);
    }

    public async Task<ManagedUserDto?> UpdateUserAsync(int id, SaveManagedUserRequest request, int actorId, CancellationToken cancellationToken = default)
    {
        var user = await dbContext.Users.Include(x => x.UserRoles).SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (user is null) return null;
        if (id == actorId && !request.IsActive)
            throw new BusinessRuleException("Ne mozete deaktivirati vlastiti administratorski nalog.");
        var email = request.Email.Trim().ToLowerInvariant();
        var userName = request.UserName.Trim();
        if (await dbContext.Users.AnyAsync(x => x.Id != id && (x.Email == email || x.UserName == userName), cancellationToken))
            throw new BusinessRuleException("Email adresa ili korisnicko ime vec postoji.");
        var role = await dbContext.Roles.SingleOrDefaultAsync(x => x.Name == request.Role, cancellationToken)
            ?? throw new ResourceNotFoundException("Uloga nije pronadjena.");
        user.FirstName = request.FirstName.Trim();
        user.LastName = request.LastName.Trim();
        user.Email = email;
        user.UserName = userName;
        user.PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim();
        user.IsActive = request.IsActive;
        user.UpdatedAtUtc = DateTime.UtcNow;
        if (!string.IsNullOrWhiteSpace(request.Password)) user.PasswordHash = PasswordHash.Create(request.Password);
        dbContext.Set<UserRole>().RemoveRange(user.UserRoles);
        user.UserRoles = [new UserRole { UserId = user.Id, RoleId = role.Id }];
        if (!user.IsActive)
        {
            var tokens = await dbContext.RefreshTokens.Where(x => x.UserId == id && x.RevokedAtUtc == null).ToListAsync(cancellationToken);
            foreach (var token in tokens) token.RevokedAtUtc = DateTime.UtcNow;
        }
        await dbContext.SaveChangesAsync(cancellationToken);
        return await dbContext.Users.AsNoTracking().Where(x => x.Id == id)
            .Select(ManagedUserProjection()).SingleAsync(cancellationToken);
    }

    public async Task<bool> DeleteUserAsync(int id, int actorId, CancellationToken cancellationToken = default)
    {
        if (id == actorId) throw new BusinessRuleException("Ne mozete obrisati vlastiti administratorski nalog.");
        var user = await dbContext.Users.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (user is null) return false;
        user.IsActive = false;
        user.DeletedAtUtc = DateTime.UtcNow;
        user.UpdatedAtUtc = DateTime.UtcNow;
        var tokens = await dbContext.RefreshTokens.Where(x => x.UserId == id && x.RevokedAtUtc == null).ToListAsync(cancellationToken);
        foreach (var token in tokens) token.RevokedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static System.Linq.Expressions.Expression<Func<User, UserDto>> UserProjection() => x =>
        new UserDto(x.Id, x.FirstName, x.LastName, x.Email, x.UserName, x.PhoneNumber, x.IsActive,
            x.UserRoles.Select(ur => ur.Role.Name).OrderBy(name => name).ToList(), x.ProfileImageUrl);

    private static System.Linq.Expressions.Expression<Func<User, ManagedUserDto>> ManagedUserProjection() => x =>
        new ManagedUserDto(x.Id, x.FirstName, x.LastName, x.Email, x.UserName, x.PhoneNumber, x.IsActive,
            x.UserRoles.Select(ur => ur.Role.Name).OrderBy(name => name).ToList(), x.OwnedCabins.Count,
            x.OwnedCabins.SelectMany(cabin => cabin.Reservations).Count());
}

public sealed class ReservationService(CabinRentDbContext dbContext) : IReservationService
{
    public Task<PagedResult<ReservationDto>> GetAsync(PageRequest paging, int? guestId, int? ownerId, int? cabinId, string? status, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Reservations.AsNoTracking().AsQueryable();
        if (guestId.HasValue) query = query.Where(x => x.GuestId == guestId);
        if (ownerId.HasValue) query = query.Where(x => x.Cabin.OwnerId == ownerId);
        if (cabinId.HasValue) query = query.Where(x => x.CabinId == cabinId);
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (!Enum.TryParse<ReservationStatus>(status, true, out var parsed))
                throw new RequestValidationException("Nepoznat status rezervacije.");
            query = query.Where(x => x.Status == parsed);
        }
        return query.OrderByDescending(x => x.CheckIn).Select(Projection())
            .ToPagedResultAsync(paging, cancellationToken);
    }

    public Task<ReservationDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default) =>
        dbContext.Reservations.AsNoTracking().Where(x => x.Id == id).Select(Projection()).SingleOrDefaultAsync(cancellationToken);

    public async Task<ReservationDto> CreateAsync(CreateReservationRequest request, int guestId, CancellationToken cancellationToken = default)
    {
        if (request.CheckOut <= request.CheckIn) throw new RequestValidationException("Check-out mora biti nakon check-in datuma.");
        var cabin = await dbContext.Cabins.Where(CabinVisibilityRules.PubliclyVisible)
            .SingleOrDefaultAsync(x => x.Id == request.CabinId, cancellationToken)
            ?? throw new ResourceNotFoundException("Vikendica nije pronađena.");
        if (!await dbContext.Users.AnyAsync(x => x.Id == guestId && x.IsActive, cancellationToken))
            throw new ResourceNotFoundException("Gost nije pronađen.");
        if (request.Adults + request.Children > cabin.MaxAdults + cabin.MaxChildren)
            throw new RequestValidationException("Broj gostiju prelazi kapacitet vikendice.");

        var overlaps = await dbContext.Reservations.AnyAsync(x => x.CabinId == request.CabinId &&
            x.Status != ReservationStatus.Cancelled && x.Status != ReservationStatus.Rejected &&
            request.CheckIn < x.CheckOut && request.CheckOut > x.CheckIn, cancellationToken);
        var blocked = await dbContext.AvailabilityBlocks.AnyAsync(x => x.CabinId == request.CabinId &&
            request.CheckIn < x.To && request.CheckOut > x.From, cancellationToken);
        if (overlaps || blocked) throw new BusinessRuleException("Vikendica nije dostupna u odabranom terminu.");

        var nights = request.CheckOut.DayNumber - request.CheckIn.DayNumber;
        var reservation = new Reservation
        {
            CabinId = request.CabinId, GuestId = guestId, CheckIn = request.CheckIn, CheckOut = request.CheckOut,
            Adults = request.Adults, Children = request.Children, SpecialRequests = request.SpecialRequests,
            PricePerNight = cabin.PricePerNight, TotalPrice = cabin.PricePerNight * nights,
            Payment = new Payment { Amount = cabin.PricePerNight * nights, Currency = "BAM", Provider = "Pending", Status = PaymentStatus.Pending }
        };
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        dbContext.Reservations.Add(reservation);
        await dbContext.SaveChangesAsync(cancellationToken);
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), cabin.OwnerId, "ReservationCreated", "Nova rezervacija",
            $"Primljena je nova rezervacija {reservation.ConfirmationCode} za vikendicu {cabin.Name}.",
            "Reservation", reservation.Id, DateTime.UtcNow));
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return (await GetByIdAsync(reservation.Id, cancellationToken))!;
    }

    public async Task<ReservationDto?> UpdateStatusAsync(int id, UpdateReservationStatusRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        if (!Enum.TryParse<ReservationStatus>(request.Status, true, out var status))
            throw new RequestValidationException("Nepoznat status rezervacije.");
        var reason = request.Reason?.Trim();
        if (status == ReservationStatus.Rejected && string.IsNullOrWhiteSpace(reason))
            throw new RequestValidationException("Razlog odbijanja rezervacije je obavezan.");
        var reservation = await dbContext.Reservations.Include(x => x.Cabin).Include(x => x.Payment)
            .SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (reservation is null) return null;
        if (!isAdmin && reservation.Cabin.OwnerId != actorId) throw new ForbiddenOperationException("Nemate pristup ovoj rezervaciji.");
        if (reservation.Status == status) return await GetByIdAsync(id, cancellationToken);
        if (status == ReservationStatus.Cancelled && reservation.Payment?.Status == PaymentStatus.Paid)
            throw new BusinessRuleException("Plaćena rezervacija mora biti otkazana kroz Stripe refund tok.");
        if (!ReservationStatusRules.CanTransition(reservation.Status, status))
            throw new BusinessRuleException($"Status rezervacije nije moguće promijeniti iz {reservation.Status} u {status}.");
        reservation.Status = status;
        reservation.UpdatedAtUtc = DateTime.UtcNow;
        reservation.StatusChangedByUserId = actorId;
        reservation.StatusChangedAtUtc = DateTime.UtcNow;
        reservation.StatusChangeReason = string.IsNullOrWhiteSpace(reason) ? null : reason;
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.GuestId, "ReservationStatusChanged", "Promijenjen status rezervacije",
            $"Rezervacija {reservation.ConfirmationCode} sada ima status {StatusLabel(status)}.",
            "Reservation", reservation.Id, DateTime.UtcNow));
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task<ReservationDto?> CancelAsync(int id, int guestId, CancellationToken cancellationToken = default)
    {
        var reservation = await dbContext.Reservations.Include(x => x.Cabin).Include(x => x.Payment)
            .SingleOrDefaultAsync(x => x.Id == id && x.GuestId == guestId, cancellationToken);
        if (reservation is null) return null;
        if (!ReservationStatusRules.CanGuestCancel(reservation.Status, reservation.CheckIn, DateOnly.FromDateTime(DateTime.UtcNow)))
            throw new BusinessRuleException("Rezervaciju je moguće otkazati samo prije dana dolaska dok je na čekanju ili potvrđena.");

        if (reservation.Payment?.Status == PaymentStatus.Paid)
            throw new BusinessRuleException("Plaćena rezervacija mora biti otkazana kroz Stripe refund tok.");
        reservation.Status = ReservationStatus.Cancelled;
        reservation.UpdatedAtUtc = DateTime.UtcNow;
        reservation.StatusChangedByUserId = guestId;
        reservation.StatusChangedAtUtc = DateTime.UtcNow;
        reservation.StatusChangeReason = "Rezervaciju je otkazao gost.";
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.Cabin.OwnerId, "ReservationCancelled", "Otkazana rezervacija",
            $"Gost je otkazao rezervaciju {reservation.ConfirmationCode} za vikendicu {reservation.Cabin.Name}.",
            "Reservation", reservation.Id, DateTime.UtcNow));
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task<ReservationDto?> RescheduleAsync(int id, RescheduleReservationRequest request, int guestId, CancellationToken cancellationToken = default)
    {
        if (request.CheckOut <= request.CheckIn)
            throw new RequestValidationException("Datum odlaska mora biti nakon datuma dolaska.");
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        if (request.CheckIn <= today)
            throw new RequestValidationException("Novi datum dolaska mora biti u budućnosti.");

        var reservation = await dbContext.Reservations
            .Include(x => x.Cabin).ThenInclude(x => x.Owner)
            .Include(x => x.Payment)
            .SingleOrDefaultAsync(x => x.Id == id && x.GuestId == guestId, cancellationToken);
        if (reservation is null) return null;
        if (!ReservationStatusRules.CanGuestReschedule(reservation.Status, reservation.CheckIn, today, reservation.Payment?.Status))
            throw new BusinessRuleException("Termin je moguće promijeniti samo za buduću neplaćenu rezervaciju koja je na čekanju ili potvrđena.");
        if (!reservation.Cabin.IsActive || !reservation.Cabin.Owner.IsActive)
            throw new BusinessRuleException("Vikendica trenutno nije dostupna za rezervaciju.");

        var overlaps = await dbContext.Reservations.AnyAsync(x => x.Id != reservation.Id &&
            x.CabinId == reservation.CabinId &&
            x.Status != ReservationStatus.Cancelled && x.Status != ReservationStatus.Rejected &&
            request.CheckIn < x.CheckOut && request.CheckOut > x.CheckIn, cancellationToken);
        var blocked = await dbContext.AvailabilityBlocks.AnyAsync(x => x.CabinId == reservation.CabinId &&
            request.CheckIn < x.To && request.CheckOut > x.From, cancellationToken);
        if (overlaps || blocked)
            throw new BusinessRuleException("Vikendica nije dostupna u odabranom terminu.");

        var nights = request.CheckOut.DayNumber - request.CheckIn.DayNumber;
        var totalPrice = reservation.Cabin.PricePerNight * nights;
        reservation.CheckIn = request.CheckIn;
        reservation.CheckOut = request.CheckOut;
        reservation.PricePerNight = reservation.Cabin.PricePerNight;
        reservation.TotalPrice = totalPrice;
        reservation.Status = ReservationStatus.Pending;
        reservation.UpdatedAtUtc = DateTime.UtcNow;
        if (reservation.Payment is null)
        {
            reservation.Payment = new Payment
            {
                Amount = totalPrice,
                Currency = "BAM",
                Provider = "Pending",
                Status = PaymentStatus.Pending
            };
        }
        else
        {
            reservation.Payment.Amount = totalPrice;
            reservation.Payment.Provider = "Pending";
            reservation.Payment.ProviderReference = null;
            reservation.Payment.Status = PaymentStatus.Pending;
            reservation.Payment.PaidAtUtc = null;
            reservation.Payment.UpdatedAtUtc = DateTime.UtcNow;
        }
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.Cabin.OwnerId, "ReservationRescheduled", "Zatražena promjena termina",
            $"Gost je promijenio termin rezervacije {reservation.ConfirmationCode} za vikendicu {reservation.Cabin.Name}. Potrebna je nova potvrda.",
            "Reservation", reservation.Id, DateTime.UtcNow));
        await dbContext.SaveChangesAsync(cancellationToken);
        return await GetByIdAsync(id, cancellationToken);
    }

    private static System.Linq.Expressions.Expression<Func<Reservation, ReservationDto>> Projection() => x =>
        new ReservationDto(x.Id, x.ConfirmationCode, x.CabinId, x.Cabin.Name, x.Cabin.OwnerId, x.GuestId,
            x.Guest.FirstName + " " + x.Guest.LastName, x.Guest.Email, x.Guest.PhoneNumber,
            x.CheckIn, x.CheckOut, x.Adults, x.Children, x.PricePerNight, x.TotalPrice,
              x.Status.ToString(), x.SpecialRequests, x.Payment == null ? null : x.Payment.Status.ToString(),
              x.Payment != null && (x.Payment.Status == PaymentStatus.Paid || x.Payment.Status == PaymentStatus.Refunded)
                  ? x.Payment.ChargedAmount ?? x.Payment.Amount : 0,
              x.Payment == null ? null : x.Payment.Currency,
              x.Payment == null ? null : x.Payment.PaidAtUtc,
              x.Payment == null ? 0 : x.Payment.RefundedAmount,
              x.Payment == null ? null : x.Payment.RefundedAtUtc,
              x.StatusChangedByUserId,
              x.StatusChangedByUser == null ? null : x.StatusChangedByUser.FirstName + " " + x.StatusChangedByUser.LastName,
              x.StatusChangedAtUtc, x.StatusChangeReason,
              x.CreatedAtUtc);

    private static string StatusLabel(ReservationStatus status) => status switch
    {
        ReservationStatus.Confirmed => "potvrđena",
        ReservationStatus.Completed => "završena",
        ReservationStatus.Cancelled => "otkazana",
        ReservationStatus.Rejected => "odbijena",
        _ => "na čekanju"
    };
}

public sealed class ReviewService(CabinRentDbContext dbContext) : IReviewService
{
    public Task<PagedResult<ReviewDto>> GetAsync(PageRequest paging, int? cabinId, bool? approved, CancellationToken cancellationToken = default)
    {
        var query = dbContext.Reviews.AsNoTracking()
            .Where(x => x.Cabin.IsActive && x.Cabin.Owner.IsActive)
            .AsQueryable();
        if (cabinId.HasValue) query = query.Where(x => x.CabinId == cabinId);
        if (approved.HasValue) query = query.Where(x => x.IsApproved == approved);
        return query.OrderByDescending(x => x.CreatedAtUtc).Select(Projection())
            .ToPagedResultAsync(paging, cancellationToken);
    }

    public Task<PagedResult<ReviewDto>> GetMineAsync(PageRequest paging, int guestId, CancellationToken cancellationToken = default) =>
        dbContext.Reviews.AsNoTracking()
            .Where(x => x.GuestId == guestId)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Select(Projection())
            .ToPagedResultAsync(paging, cancellationToken);

    public Task<PagedResult<ReviewDto>> GetManagedAsync(PageRequest paging, int? ownerId, int? cabinId, int? rating, bool? approved, string? search, CancellationToken cancellationToken = default)
    {
        if (rating is < 1 or > 5) throw new RequestValidationException("Ocjena mora biti između 1 i 5.");
        var query = dbContext.Reviews.AsNoTracking().AsQueryable();
        if (ownerId.HasValue) query = query.Where(x => x.Cabin.OwnerId == ownerId);
        if (cabinId.HasValue) query = query.Where(x => x.CabinId == cabinId);
        if (rating.HasValue) query = query.Where(x => x.Rating == rating.Value);
        if (approved.HasValue) query = query.Where(x => x.IsApproved == approved.Value);
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim();
            query = query.Where(x => x.Guest.FirstName.Contains(term) || x.Guest.LastName.Contains(term) ||
                (x.Comment != null && x.Comment.Contains(term)) || x.Cabin.Name.Contains(term));
        }
        return query.OrderByDescending(x => x.CreatedAtUtc).Select(Projection())
            .ToPagedResultAsync(paging, cancellationToken);
    }

    public async Task<ReviewDto> CreateAsync(CreateReviewRequest request, int guestId, CancellationToken cancellationToken = default)
    {
        var reservation = await dbContext.Reservations.Include(x => x.Review).Include(x => x.Cabin).SingleOrDefaultAsync(x => x.Id == request.ReservationId, cancellationToken)
            ?? throw new ResourceNotFoundException("Rezervacija nije pronađena.");
        if (reservation.Status != ReservationStatus.Completed) throw new BusinessRuleException("Recenzija je dozvoljena tek nakon završenog boravka.");
        if (reservation.GuestId != guestId) throw new ForbiddenOperationException("Nemate pristup ovoj rezervaciji.");
        if (reservation.Review is not null) throw new BusinessRuleException("Rezervacija već ima recenziju.");
        var review = new Review { Reservation = reservation, CabinId = reservation.CabinId, GuestId = reservation.GuestId, Rating = request.Rating, Comment = request.Comment, IsApproved = false };
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        dbContext.Reviews.Add(review);
        await dbContext.SaveChangesAsync(cancellationToken);
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.Cabin.OwnerId, "ReviewCreated", "Nova recenzija",
            $"Gost je ostavio novu recenziju za vikendicu {reservation.Cabin.Name}.",
            "Review", review.Id, DateTime.UtcNow));
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return await dbContext.Reviews.AsNoTracking().Where(x => x.Id == review.Id).Select(Projection()).SingleAsync(cancellationToken);
    }

    public async Task<ReviewDto?> SetApprovalAsync(int id, bool isApproved, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var review = await dbContext.Reviews.Include(x => x.Cabin).SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (review is null) return null;
        if (!ReviewModerationRules.CanManage(isAdmin, review.Cabin.OwnerId, actorId))
            throw new ForbiddenOperationException("Nemate pristup ovoj recenziji.");
        review.IsApproved = isApproved;
        review.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return await dbContext.Reviews.AsNoTracking().Where(x => x.Id == id).Select(Projection()).SingleAsync(cancellationToken);
    }

    public async Task<ReviewDto?> UpdateAsync(int id, UpdateReviewRequest request, int guestId, CancellationToken cancellationToken = default)
    {
        var review = await dbContext.Reviews.SingleOrDefaultAsync(x => x.Id == id && x.GuestId == guestId, cancellationToken);
        if (review is null) return null;
        review.Rating = request.Rating;
        review.Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim();
        review.IsApproved = false;
        review.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return await dbContext.Reviews.AsNoTracking().Where(x => x.Id == id).Select(Projection()).SingleAsync(cancellationToken);
    }

    public async Task<bool> DeleteAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var review = await dbContext.Reviews.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (review is null) return false;
        if (!isAdmin && review.GuestId != actorId)
            throw new ForbiddenOperationException("Nemate pristup ovoj recenziji.");
        dbContext.Reviews.Remove(review);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static System.Linq.Expressions.Expression<Func<Review, ReviewDto>> Projection() => x =>
        new ReviewDto(x.Id, x.ReservationId, x.CabinId, x.Cabin.Name, x.GuestId,
            x.Guest.FirstName + " " + x.Guest.LastName, x.Guest.Email, x.Rating, x.Comment, x.IsApproved, x.CreatedAtUtc);
}

public sealed class FavoriteService(CabinRentDbContext dbContext) : IFavoriteService
{
    public Task<PagedResult<FavoriteDto>> GetAsync(PageRequest paging, int userId, CancellationToken cancellationToken = default) =>
        dbContext.Favorites.AsNoTracking()
            .Where(x => x.UserId == userId && x.Cabin.IsActive && x.Cabin.Owner.IsActive)
            .OrderByDescending(x => x.CreatedAtUtc)
            .Select(x => new FavoriteDto(x.UserId, x.CabinId, x.Cabin.Name, x.Cabin.PricePerNight, x.CreatedAtUtc))
            .ToPagedResultAsync(paging, cancellationToken);

    public async Task<FavoriteDto> AddAsync(AddFavoriteRequest request, int userId, CancellationToken cancellationToken = default)
    {
        if (!await dbContext.Users.AnyAsync(x => x.Id == userId && x.IsActive, cancellationToken)
            || !await dbContext.Cabins.Where(CabinVisibilityRules.PubliclyVisible).AnyAsync(x => x.Id == request.CabinId, cancellationToken))
            throw new ResourceNotFoundException("Korisnik ili vikendica nije pronađena.");
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
