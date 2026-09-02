namespace CabinRent.Infrastructure.Platform;

public static class ReservationCreationRules
{
    public static bool IsCheckInInFuture(DateOnly checkIn, DateOnly today) =>
        checkIn > today;

    public static bool HasValidGuestCounts(int adults, int children) =>
        adults >= 1 && children >= 0;

    public static bool FitsCabinCapacity(
        int adults,
        int children,
        int maxAdults,
        int maxChildren) =>
        adults <= maxAdults && children <= maxChildren;
}