using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Recommendations;
using CabinRent.Services.Recommendations;
using Microsoft.EntityFrameworkCore;
using CabinRent.Infrastructure.Cabins;
using CabinRent.Model.Common;

namespace CabinRent.Infrastructure.Recommendations;

public sealed class RecommendationService(CabinRentDbContext dbContext) : IRecommendationService
{
    public async Task<PagedResult<RecommendationDto>> GetAsync(
        int userId, PageRequest paging, CancellationToken cancellationToken = default)
    {
        var page = Math.Max(paging.Page, 1);
        var pageSize = Math.Clamp(paging.PageSize, 1, 20);
        var preferences = await dbContext.Cabins.AsNoTracking()
            .Where(cabin =>
                cabin.Reservations.Any(reservation => reservation.GuestId == userId
                    && reservation.Status == ReservationStatus.Completed)
                || dbContext.Favorites.Any(favorite => favorite.UserId == userId && favorite.CabinId == cabin.Id))
            .Select(cabin => new { cabin.Id, cabin.CityId, cabin.CabinTypeId })
            .ToListAsync(cancellationToken);

        var preferredCabinIds = preferences.Select(x => x.Id).Distinct().ToArray();
        var preferredCityIds = preferences.Select(x => x.CityId).Distinct().ToArray();
        var preferredTypeIds = preferences.Select(x => x.CabinTypeId).Distinct().ToArray();
        var activelyReservedCabinIds = await dbContext.Reservations.AsNoTracking()
            .Where(x => x.GuestId == userId
                && (x.Status == ReservationStatus.Pending || x.Status == ReservationStatus.Confirmed))
            .Select(x => x.CabinId).Distinct().ToArrayAsync(cancellationToken);
        var excludedCabinIds = preferredCabinIds
            .Union(activelyReservedCabinIds)
            .ToArray();
        var guestsWithSimilarStays = preferredCabinIds.Length == 0
            ? []
            : await dbContext.Reservations.AsNoTracking()
                .Where(x => x.GuestId != userId && x.Guest.IsActive
                    && x.Status == ReservationStatus.Completed
                    && preferredCabinIds.Contains(x.CabinId))
                .Select(x => x.GuestId).Distinct().ToArrayAsync(cancellationToken);
        var guestsWithSimilarFavorites = preferredCabinIds.Length == 0
            ? []
            : await dbContext.Favorites.AsNoTracking()
                .Where(x => x.UserId != userId && x.User.IsActive
                    && preferredCabinIds.Contains(x.CabinId))
                .Select(x => x.UserId).Distinct().ToArrayAsync(cancellationToken);
        var similarGuestIds = guestsWithSimilarStays
            .Union(guestsWithSimilarFavorites)
            .ToArray();

        var candidates = await dbContext.Cabins.AsNoTracking()
            .Where(CabinVisibilityRules.PubliclyVisible)
            .Where(x => !excludedCabinIds.Contains(x.Id))
            .Select(x => new Candidate(
                x.Id,
                x.Name,
                x.City.Name,
                x.PricePerNight,
                x.MaxAdults + x.MaxChildren,
                dbContext.Reviews.Where(review => review.CabinId == x.Id && review.IsApproved)
                    .Select(review => (double?)review.Rating).Average(),
                x.Images.Where(image => image.IsCover).Select(image => image.Url).FirstOrDefault(),
                x.Reservations.Count(reservation => similarGuestIds.Contains(reservation.GuestId)
                    && reservation.Status == ReservationStatus.Completed),
                x.Reservations.Count(reservation => reservation.Status == ReservationStatus.Completed),
                dbContext.Reviews.Count(review => review.CabinId == x.Id && review.IsApproved),
                preferredCityIds.Contains(x.CityId) || preferredTypeIds.Contains(x.CabinTypeId)))
            .ToListAsync(cancellationToken);

        var personalized = preferences.Count > 0;
        var rankedCandidates = candidates
            .Select(candidate => new RecommendationDto(
                candidate.Id,
                candidate.Name,
                candidate.City,
                candidate.PricePerNight,
                candidate.MaxGuests,
                candidate.AverageRating,
                candidate.CoverImageUrl,
                RecommendationRules.Score(
                    candidate.SimilarGuestStays,
                    candidate.CompletedStays,
                    candidate.AverageRating,
                    candidate.ReviewCount,
                    candidate.MatchesPreference),
                RecommendationRules.Reason(
                    candidate.SimilarGuestStays,
                    candidate.CompletedStays,
                    candidate.AverageRating,
                    candidate.ReviewCount,
                    candidate.MatchesPreference),
                personalized))
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.AverageRating)
            .ThenByDescending(x => candidates.Single(candidate => candidate.Id == x.CabinId).CompletedStays)
            .ThenBy(x => x.Name)
            .ToList();

        var cabinsWithActivity = candidates
            .Where(candidate => candidate.SimilarGuestStays > 0
                || candidate.CompletedStays > 0
                || candidate.ReviewCount > 0)
            .Select(candidate => candidate.Id)
            .ToHashSet();
        var recommendations = cabinsWithActivity.Count > 0
            ? rankedCandidates.Where(x => cabinsWithActivity.Contains(x.CabinId))
            : rankedCandidates;

        var materialized = recommendations.ToList();
        return new PagedResult<RecommendationDto>(
            materialized.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
            materialized.Count,
            page,
            pageSize);
    }

    private sealed record Candidate(
        int Id,
        string Name,
        string City,
        decimal PricePerNight,
        int MaxGuests,
        double? AverageRating,
        string? CoverImageUrl,
        int SimilarGuestStays,
        int CompletedStays,
        int ReviewCount,
        bool MatchesPreference);
}
