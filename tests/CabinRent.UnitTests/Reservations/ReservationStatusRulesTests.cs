using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using Xunit;

namespace CabinRent.UnitTests.Reservations;

public sealed class ReservationStatusRulesTests
{
    [Theory]
    [InlineData(ReservationStatus.Pending, ReservationStatus.Confirmed)]
    [InlineData(ReservationStatus.Pending, ReservationStatus.Rejected)]
    [InlineData(ReservationStatus.Pending, ReservationStatus.Cancelled)]
    [InlineData(ReservationStatus.Confirmed, ReservationStatus.Completed)]
    [InlineData(ReservationStatus.Confirmed, ReservationStatus.Cancelled)]
    public void Supported_transition_is_allowed(ReservationStatus current, ReservationStatus next) =>
        Assert.True(ReservationStatusRules.CanTransition(current, next));

    [Theory]
    [InlineData(ReservationStatus.Pending, ReservationStatus.Completed)]
    [InlineData(ReservationStatus.Confirmed, ReservationStatus.Rejected)]
    [InlineData(ReservationStatus.Completed, ReservationStatus.Pending)]
    [InlineData(ReservationStatus.Cancelled, ReservationStatus.Confirmed)]
    [InlineData(ReservationStatus.Rejected, ReservationStatus.Pending)]
    public void Unsupported_transition_is_rejected(ReservationStatus current, ReservationStatus next) =>
        Assert.False(ReservationStatusRules.CanTransition(current, next));

    [Theory]
    [InlineData(ReservationStatus.Pending)]
    [InlineData(ReservationStatus.Confirmed)]
    public void Guest_can_cancel_upcoming_active_reservation(ReservationStatus status) =>
        Assert.True(ReservationStatusRules.CanGuestCancel(status, new DateOnly(2026, 9, 2), new DateOnly(2026, 9, 1)));

    [Theory]
    [InlineData(ReservationStatus.Cancelled, 2)]
    [InlineData(ReservationStatus.Completed, 2)]
    [InlineData(ReservationStatus.Rejected, 2)]
    [InlineData(ReservationStatus.Pending, 0)]
    [InlineData(ReservationStatus.Confirmed, -1)]
    public void Guest_cannot_cancel_invalid_reservation(ReservationStatus status, int daysUntilCheckIn) =>
        Assert.False(ReservationStatusRules.CanGuestCancel(status, new DateOnly(2026, 9, 1).AddDays(daysUntilCheckIn), new DateOnly(2026, 9, 1)));

    [Theory]
    [InlineData(ReservationStatus.Pending, PaymentStatus.Pending)]
    [InlineData(ReservationStatus.Confirmed, PaymentStatus.Failed)]
    [InlineData(ReservationStatus.Confirmed, PaymentStatus.Refunded)]
    public void Guest_can_reschedule_upcoming_unpaid_reservation(ReservationStatus status, PaymentStatus paymentStatus) =>
        Assert.True(ReservationStatusRules.CanGuestReschedule(
            status, new DateOnly(2026, 9, 5), new DateOnly(2026, 9, 1), paymentStatus));

    [Theory]
    [InlineData(ReservationStatus.Completed, PaymentStatus.Pending, 5)]
    [InlineData(ReservationStatus.Cancelled, PaymentStatus.Pending, 5)]
    [InlineData(ReservationStatus.Rejected, PaymentStatus.Pending, 5)]
    [InlineData(ReservationStatus.Pending, PaymentStatus.Paid, 5)]
    [InlineData(ReservationStatus.Confirmed, PaymentStatus.Pending, 0)]
    [InlineData(ReservationStatus.Confirmed, PaymentStatus.Pending, -1)]
    public void Guest_cannot_reschedule_invalid_reservation(
        ReservationStatus status, PaymentStatus paymentStatus, int daysUntilCheckIn) =>
        Assert.False(ReservationStatusRules.CanGuestReschedule(
            status, new DateOnly(2026, 9, 1).AddDays(daysUntilCheckIn), new DateOnly(2026, 9, 1), paymentStatus));

    [Fact]
    public void Stay_can_be_completed_on_check_out_date()
    {
        var result = ReservationStatusRules.CanComplete(
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 9, 5));

        Assert.True(result);
    }

    [Fact]
    public void Stay_can_be_completed_after_check_out_date()
    {
        var result = ReservationStatusRules.CanComplete(
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 9, 6));

        Assert.True(result);
    }

    [Fact]
    public void Stay_cannot_be_completed_before_check_out_date()
    {
        var result = ReservationStatusRules.CanComplete(
            new DateOnly(2026, 9, 5),
            new DateOnly(2026, 9, 4));

        Assert.False(result);
    }
}
