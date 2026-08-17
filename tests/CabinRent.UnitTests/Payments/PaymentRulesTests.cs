using CabinRent.Infrastructure.Payments;
using CabinRent.Infrastructure.Persistence;
using Xunit;

namespace CabinRent.UnitTests.Payments;

public sealed class PaymentRulesTests
{
    [Fact]
    public void Confirmed_future_unpaid_reservation_can_be_paid() =>
        Assert.True(PaymentRules.CanStartPayment(
            ReservationStatus.Confirmed,
            PaymentStatus.Pending,
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 8, 18)));

    [Theory]
    [InlineData(ReservationStatus.Pending, PaymentStatus.Pending)]
    [InlineData(ReservationStatus.Cancelled, PaymentStatus.Pending)]
    [InlineData(ReservationStatus.Completed, PaymentStatus.Pending)]
    [InlineData(ReservationStatus.Confirmed, PaymentStatus.Paid)]
    [InlineData(ReservationStatus.Confirmed, PaymentStatus.Refunded)]
    public void Invalid_reservation_or_payment_status_cannot_start_payment(
        ReservationStatus reservationStatus,
        PaymentStatus paymentStatus) =>
        Assert.False(PaymentRules.CanStartPayment(
            reservationStatus,
            paymentStatus,
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 8, 18)));

    [Fact]
    public void Past_reservation_cannot_be_paid() =>
        Assert.False(PaymentRules.CanStartPayment(
            ReservationStatus.Confirmed,
            PaymentStatus.Pending,
            new DateOnly(2026, 8, 18),
            new DateOnly(2026, 8, 18)));

    [Theory]
    [InlineData("1200.00", 120000)]
    [InlineData("145.50", 14550)]
    [InlineData("0.01", 1)]
    public void Amount_is_converted_to_minor_units(string value, long expected) =>
        Assert.Equal(expected, PaymentRules.ToMinorUnits(decimal.Parse(value, System.Globalization.CultureInfo.InvariantCulture)));
}
