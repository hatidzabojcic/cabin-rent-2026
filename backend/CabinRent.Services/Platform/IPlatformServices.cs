using CabinRent.Model.Catalog;
using CabinRent.Model.Favorites;
using CabinRent.Model.Reservations;
using CabinRent.Model.Reviews;
using CabinRent.Model.Users;
using CabinRent.Model.Reports;
using CabinRent.Model.Common;

namespace CabinRent.Services.Platform;

public interface IPlatformQueryService
{
    Task<PagedResult<CountryDto>> GetCountriesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default);
    Task<PagedResult<CityDto>> GetCitiesAsync(PageRequest paging, int? countryId, string? search, CancellationToken cancellationToken = default);
    Task<PagedResult<CabinTypeDto>> GetCabinTypesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default);
    Task<PagedResult<AmenityDto>> GetAmenitiesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default);
    Task<PagedResult<RoleDto>> GetRolesAsync(PageRequest paging, string? search, CancellationToken cancellationToken = default);
    Task<PagedResult<UserDto>> GetUsersAsync(PageRequest paging, string? search, string? role, CancellationToken cancellationToken = default);
    Task<UserDto?> GetUserAsync(int id, CancellationToken cancellationToken = default);
    Task<PagedResult<ManagedUserDto>> GetManagedUsersAsync(PageRequest paging, string? search, string? role, bool? isActive, CancellationToken cancellationToken = default);
    Task<ManagedUserDto?> SetUserActiveAsync(int id, bool isActive, int actorId, CancellationToken cancellationToken = default);
    Task<ManagedUserDto> CreateUserAsync(SaveManagedUserRequest request, CancellationToken cancellationToken = default);
    Task<ManagedUserDto?> UpdateUserAsync(int id, SaveManagedUserRequest request, int actorId, CancellationToken cancellationToken = default);
    Task<bool> DeleteUserAsync(int id, int actorId, CancellationToken cancellationToken = default);
}

public interface IReferenceDataService
{
    Task<CountryDto> CreateCountryAsync(SaveCountryRequest request, CancellationToken cancellationToken = default);
    Task<CountryDto?> UpdateCountryAsync(int id, SaveCountryRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteCountryAsync(int id, CancellationToken cancellationToken = default);
    Task<CityDto> CreateCityAsync(SaveCityRequest request, CancellationToken cancellationToken = default);
    Task<CityDto?> UpdateCityAsync(int id, SaveCityRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteCityAsync(int id, CancellationToken cancellationToken = default);
    Task<CabinTypeDto> CreateCabinTypeAsync(SaveCabinTypeRequest request, CancellationToken cancellationToken = default);
    Task<CabinTypeDto?> UpdateCabinTypeAsync(int id, SaveCabinTypeRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteCabinTypeAsync(int id, CancellationToken cancellationToken = default);
    Task<AmenityDto> CreateAmenityAsync(SaveAmenityRequest request, CancellationToken cancellationToken = default);
    Task<AmenityDto?> UpdateAmenityAsync(int id, SaveAmenityRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteAmenityAsync(int id, CancellationToken cancellationToken = default);
    Task<RoleDto> CreateRoleAsync(SaveRoleRequest request, CancellationToken cancellationToken = default);
    Task<RoleDto?> UpdateRoleAsync(int id, SaveRoleRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteRoleAsync(int id, CancellationToken cancellationToken = default);
}

public interface IReservationService
{
    Task<PagedResult<ReservationDto>> GetAsync(PageRequest paging, int? guestId, int? ownerId, int? cabinId, string? status, CancellationToken cancellationToken = default);
    Task<ReservationDto?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<ReservationDto> CreateAsync(CreateReservationRequest request, int guestId, CancellationToken cancellationToken = default);
    Task<ReservationDto?> UpdateStatusAsync(int id, UpdateReservationStatusRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<ReservationDto?> CancelAsync(int id, int guestId, CancellationToken cancellationToken = default);
    Task<ReservationDto?> RescheduleAsync(int id, RescheduleReservationRequest request, int guestId, CancellationToken cancellationToken = default);
}

public interface IReviewService
{
    Task<PagedResult<ReviewDto>> GetAsync(PageRequest paging, int? cabinId, bool? approved, CancellationToken cancellationToken = default);
    Task<PagedResult<ReviewDto>> GetMineAsync(PageRequest paging, int guestId, CancellationToken cancellationToken = default);
    Task<PagedResult<ReviewDto>> GetManagedAsync(PageRequest paging, int? ownerId, int? cabinId, int? rating, bool? approved, string? search, CancellationToken cancellationToken = default);
    Task<ReviewDto> CreateAsync(CreateReviewRequest request, int guestId, CancellationToken cancellationToken = default);
    Task<ReviewDto?> SetApprovalAsync(int id, bool isApproved, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
    Task<ReviewDto?> UpdateAsync(int id, UpdateReviewRequest request, int guestId, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default);
}

public interface IFavoriteService
{
    Task<PagedResult<FavoriteDto>> GetAsync(PageRequest paging, int userId, CancellationToken cancellationToken = default);
    Task<FavoriteDto> AddAsync(AddFavoriteRequest request, int userId, CancellationToken cancellationToken = default);
    Task<bool> RemoveAsync(int userId, int cabinId, CancellationToken cancellationToken = default);
}

public interface IReportService
{
    Task<AnnualReportDto> GetAnnualAsync(int year, int? ownerId, int? cabinId, CancellationToken cancellationToken = default);
    Task<TopGuestsReportDto> GetTopGuestsAsync(int year, int? cabinId, int limit, CancellationToken cancellationToken = default);
}
