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

    public static decimal FromMinorUnits(long amount) => amount / 100m;

    public static bool MatchesExpectedPayment(decimal expectedAmount, string expectedCurrency, long amountReceived, string currency) =>
        ToMinorUnits(expectedAmount) == amountReceived &&
        string.Equals(expectedCurrency, currency, StringComparison.OrdinalIgnoreCase);
}
