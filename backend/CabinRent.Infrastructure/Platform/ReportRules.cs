using CabinRent.Infrastructure.Persistence;

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
}
