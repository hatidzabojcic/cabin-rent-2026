using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Recommendations;
using CabinRent.Services.Recommendations;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Recommendations;

public sealed class RecommendationService(CabinRentDbContext dbContext) : IRecommendationService
{
    public async Task<IReadOnlyCollection<RecommendationDto>> GetAsync(
        int userId, int limit, CancellationToken cancellationToken = default)
    {
        var resultLimit = Math.Clamp(limit, 1, 20);
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
        var completedCabinIds = await dbContext.Reservations.AsNoTracking()
            .Where(x => x.GuestId == userId && x.Status == ReservationStatus.Completed)
            .Select(x => x.CabinId).Distinct().ToArrayAsync(cancellationToken);

        var similarGuestIds = preferredCabinIds.Length == 0
            ? []
            : await dbContext.Reservations.AsNoTracking()
                .Where(x => x.GuestId != userId && x.Status == ReservationStatus.Completed
                    && preferredCabinIds.Contains(x.CabinId))
                .Select(x => x.GuestId).Distinct().ToArrayAsync(cancellationToken);

        var candidates = await dbContext.Cabins.AsNoTracking()
            .Where(x => x.IsActive && !completedCabinIds.Contains(x.Id))
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
                dbContext.Favorites.Count(favorite => favorite.CabinId == x.Id),
                preferredCityIds.Contains(x.CityId) || preferredTypeIds.Contains(x.CabinTypeId)))
            .ToListAsync(cancellationToken);

        var personalized = preferences.Count > 0;
        return candidates
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
                    candidate.FavoriteCount,
                    candidate.MatchesPreference),
                RecommendationRules.Reason(
                    candidate.SimilarGuestStays,
                    candidate.MatchesPreference,
                    candidate.AverageRating,
                    candidate.ReviewCount),
                personalized))
            .OrderByDescending(x => x.Score)
            .ThenByDescending(x => x.AverageRating)
            .ThenBy(x => x.Name)
            .Take(resultLimit)
            .ToList();
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
        int FavoriteCount,
        bool MatchesPreference);
}
