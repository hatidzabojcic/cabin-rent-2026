using CabinRent.Infrastructure.Persistence;

namespace CabinRent.Infrastructure.Platform;

public static class ReservationStatusRules
{
    public static bool CanTransition(ReservationStatus current, ReservationStatus next) =>
        current switch
        {
            ReservationStatus.Pending => next is ReservationStatus.Confirmed
                or ReservationStatus.Rejected
                or ReservationStatus.Cancelled,
            ReservationStatus.Confirmed => next is ReservationStatus.Completed
                or ReservationStatus.Cancelled,
            _ => false
        };

    public static IReadOnlyCollection<ReservationStatus> AllowedFrom(ReservationStatus current) =>
        current switch
        {
            ReservationStatus.Pending =>
                [ReservationStatus.Confirmed, ReservationStatus.Rejected, ReservationStatus.Cancelled],
            ReservationStatus.Confirmed =>
                [ReservationStatus.Completed, ReservationStatus.Cancelled],
            _ => []
        };
}
