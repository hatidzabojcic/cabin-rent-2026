using CabinRent.Infrastructure.Payments;
using CabinRent.Infrastructure.Persistence;
using Xunit;

namespace CabinRent.UnitTests.Payments;

public sealed class PaymentRulesTests
{
    [Fact]
    public void Confirmed_reservation_with_future_check_in_can_be_paid()
    {
        var result = PaymentRules.CanStartPayment(
            ReservationStatus.Confirmed,
            PaymentStatus.Pending,
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 9, 1));

        Assert.True(result);
    }

    [Fact]
    public void Reservation_cannot_be_paid_on_check_in_date()
    {
        var result = PaymentRules.CanStartPayment(
            ReservationStatus.Confirmed,
            PaymentStatus.Pending,
            new DateOnly(2026, 9, 1),
            new DateOnly(2026, 9, 1));

        Assert.False(result);
    }

    [Fact]
    public void Reservation_cannot_be_paid_after_check_in()
    {
        var result = PaymentRules.CanStartPayment(
            ReservationStatus.Confirmed,
            PaymentStatus.Pending,
            new DateOnly(2026, 8, 30),
            new DateOnly(2026, 9, 1));

        Assert.False(result);
    }

    [Theory]
    [InlineData(ReservationStatus.Pending)]
    [InlineData(ReservationStatus.Cancelled)]
    [InlineData(ReservationStatus.Rejected)]
    [InlineData(ReservationStatus.Completed)]
    public void Reservation_that_is_not_confirmed_cannot_be_paid(
        ReservationStatus reservationStatus)
    {
        var result = PaymentRules.CanStartPayment(
            reservationStatus,
            PaymentStatus.Pending,
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 9, 1));

        Assert.False(result);
    }

    [Theory]
    [InlineData(PaymentStatus.Paid)]
    [InlineData(PaymentStatus.Refunded)]
    public void Paid_or_refunded_reservation_cannot_be_paid_again(
        PaymentStatus paymentStatus)
    {
        var result = PaymentRules.CanStartPayment(
            ReservationStatus.Confirmed,
            paymentStatus,
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 9, 1));

        Assert.False(result);
    }

    [Theory]
    [InlineData("1200.00", 120000)]
    [InlineData("145.50", 14550)]
    [InlineData("0.01", 1)]
    public void Amount_is_converted_to_minor_units(string value, long expected) =>
        Assert.Equal(expected, PaymentRules.ToMinorUnits(decimal.Parse(value, System.Globalization.CultureInfo.InvariantCulture)));

    [Theory]
    [InlineData("1200.00", 120000, "BAM", true)]
    [InlineData("1200.00", 119999, "BAM", false)]
    [InlineData("1200.00", 120000, "EUR", false)]
    public void Received_payment_must_match_expected_amount_and_currency(
        string expectedAmount,
        long receivedAmount,
        string receivedCurrency,
        bool expected) =>
        Assert.Equal(expected, PaymentRules.MatchesExpectedPayment(
            decimal.Parse(expectedAmount, System.Globalization.CultureInfo.InvariantCulture),
            "BAM",
            receivedAmount,
            receivedCurrency));
}
