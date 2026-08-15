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
}
