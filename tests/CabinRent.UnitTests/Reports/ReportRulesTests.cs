using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using Xunit;

namespace CabinRent.UnitTests.Reports;

public sealed class ReportRulesTests
{
    [Theory]
    [InlineData(ReservationStatus.Confirmed, true)]
    [InlineData(ReservationStatus.Completed, true)]
    [InlineData(ReservationStatus.Pending, false)]
    [InlineData(ReservationStatus.Cancelled, false)]
    [InlineData(ReservationStatus.Rejected, false)]
    public void Only_confirmed_and_completed_reservations_are_included(ReservationStatus status, bool expected) =>
        Assert.Equal(expected, ReportRules.IsIncluded(status));

    [Fact]
    public void Revenue_is_realized_only_for_completed_stays() =>
        Assert.True(ReportRules.IsRevenueRealized(ReservationStatus.Completed));

    [Fact]
    public void Nights_are_calculated_from_date_range() =>
        Assert.Equal(4, ReportRules.Nights(new DateOnly(2026, 8, 10), new DateOnly(2026, 8, 14)));
}
