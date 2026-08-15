using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Reports;

namespace CabinRent.Infrastructure.Platform;

public static class ReportRules
{
    public static bool IsValidYear(int year) => year is >= 2000 and <= 2100;
    public static bool IsIncluded(ReservationStatus status) =>
        status is ReservationStatus.Confirmed or ReservationStatus.Completed;
    public static bool IsRevenueRealized(ReservationStatus status) =>
        status == ReservationStatus.Completed;
    public static int Nights(DateOnly checkIn, DateOnly checkOut) =>
        Math.Max(0, checkOut.DayNumber - checkIn.DayNumber);

    public static IReadOnlyCollection<TopGuestDto> RankGuests(IEnumerable<TopGuestDto> guests, int limit) =>
        guests.OrderByDescending(x => x.CompletedStays)
            .ThenByDescending(x => x.Nights)
            .ThenByDescending(x => x.TotalSpent)
            .ThenBy(x => x.GuestName)
            .Take(Math.Clamp(limit, 1, 100))
            .ToList();
}
