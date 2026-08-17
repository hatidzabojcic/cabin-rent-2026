using CabinRent.Infrastructure.Auth;
using CabinRent.Infrastructure.Persistence;
using Xunit;

namespace CabinRent.UnitTests.Auth;

public sealed class ProfileDeletionRulesTests
{
    [Theory]
    [InlineData(ReservationStatus.Pending)]
    [InlineData(ReservationStatus.Confirmed)]
    public void Active_reservation_blocks_profile_deletion(ReservationStatus status) =>
        Assert.True(ProfileDeletionRules.IsBlocking(status));

    [Theory]
    [InlineData(ReservationStatus.Cancelled)]
    [InlineData(ReservationStatus.Completed)]
    [InlineData(ReservationStatus.Rejected)]
    public void Closed_reservation_allows_profile_deletion(ReservationStatus status) =>
        Assert.False(ProfileDeletionRules.IsBlocking(status));
}
