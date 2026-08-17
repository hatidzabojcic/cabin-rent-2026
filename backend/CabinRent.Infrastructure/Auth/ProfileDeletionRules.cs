using System.Linq.Expressions;
using CabinRent.Infrastructure.Persistence;

namespace CabinRent.Infrastructure.Auth;

public static class ProfileDeletionRules
{
    public static bool IsBlocking(ReservationStatus status) =>
        status is ReservationStatus.Pending or ReservationStatus.Confirmed;

    public static Expression<Func<Reservation, bool>> BlockingReservationFor(int guestId) =>
        reservation => reservation.GuestId == guestId &&
            (reservation.Status == ReservationStatus.Pending || reservation.Status == ReservationStatus.Confirmed);
}
