using CabinRent.Infrastructure.Persistence;

namespace CabinRent.Infrastructure.Payments;

public static class PaymentRules
{
    public static bool CanStartPayment(ReservationStatus reservationStatus, PaymentStatus? paymentStatus, DateOnly checkOut, DateOnly today) =>
        reservationStatus == ReservationStatus.Confirmed &&
        checkOut > today &&
        paymentStatus is not PaymentStatus.Paid and not PaymentStatus.Refunded;

    public static long ToMinorUnits(decimal amount) =>
        checked((long)decimal.Round(amount * 100m, 0, MidpointRounding.AwayFromZero));
}
