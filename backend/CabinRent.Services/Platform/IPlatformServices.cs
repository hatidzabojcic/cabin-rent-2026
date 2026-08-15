using CabinRent.Model.Catalog;
using CabinRent.Model.Favorites;
using CabinRent.Model.Reservations;
using CabinRent.Model.Reviews;
using CabinRent.Model.Users;
using CabinRent.Model.Reports;

namespace CabinRent.Services.Platform;

public interface IPlatformQueryService
{
    Task<IReadOnlyCollection<CountryDto>> GetCountriesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<CityDto>> GetCitiesAsync(int? countryId, string? search, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<CabinTypeDto>> GetCabinTypesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<AmenityDto>> GetAmenitiesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<RoleDto>> GetRolesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<UserDto>> GetUsersAsync(string? search, string? role, CancellationToken cancellationToken = default);
    Task<UserDto?> GetUserAsync(int id, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<ManagedUserDto>> GetManagedUsersAsync(string? search, string? role, bool? isActive, CancellationToken cancellationToken = default);
    Task<ManagedUserDto?> SetUserActiveAsync(int id, bool isActive, int actorId, CancellationToken cancellationToken = default);
}

public interface IReservationService
{
    Task<IReadOnlyCollection<ReservationDto>> GetAsync(int? guestId, int? ownerId, int? cabinId, string? status, CancellationToken cancellationToken = default);
    Task<ReservationDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<ReservationDto> CreateAsync(CreateReservationRequest request, int guestId, CancellationToken cancellationToken = default);
    Task<ReservationDto?> UpdateStatusAsync(int id, UpdateReservationStatusRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
}

public interface IReviewService
{
    Task<IReadOnlyCollection<ReviewDto>> GetAsync(int? cabinId, bool? approved, CancellationToken cancellationToken = default);
    Task<IReadOnlyCollection<ReviewDto>> GetManagedAsync(int? ownerId, int? cabinId, int? rating, bool? approved, string? search, CancellationToken cancellationToken = default);
    Task<ReviewDto> CreateAsync(CreateReviewRequest request, int guestId, CancellationToken cancellationToken = default);
    Task<ReviewDto?> SetApprovalAsync(int id, bool isApproved, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
}

public interface IFavoriteService
{
    Task<IReadOnlyCollection<FavoriteDto>> GetAsync(int userId, CancellationToken cancellationToken = default);
    Task<FavoriteDto> AddAsync(AddFavoriteRequest request, int userId, CancellationToken cancellationToken = default);
    Task<bool> RemoveAsync(int userId, int cabinId, CancellationToken cancellationToken = default);
}

public interface IReportService
{
    Task<AnnualReportDto> GetAnnualAsync(int year, int? ownerId, int? cabinId, CancellationToken cancellationToken = default);
}
