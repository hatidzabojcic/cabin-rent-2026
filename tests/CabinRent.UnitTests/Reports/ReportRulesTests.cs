using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using CabinRent.Model.Reports;
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

    public static TheoryData<PaymentStatus, decimal, decimal?, decimal, decimal> NetRevenueCases => new()
    {
        { PaymentStatus.Paid, 800m, 750m, 0m, 750m },
        { PaymentStatus.Paid, 800m, 750m, 100m, 650m },
        { PaymentStatus.Refunded, 800m, null, 800m, 0m },
        { PaymentStatus.Pending, 800m, null, 0m, 0m },
        { PaymentStatus.Failed, 800m, null, 0m, 0m },
        { PaymentStatus.Paid, 800m, 750m, 900m, 0m }
    };

    [Theory]
    [MemberData(nameof(NetRevenueCases))]
    public void Net_revenue_uses_collected_amount_and_subtracts_refunds(
        PaymentStatus status,
        decimal amount,
        decimal? chargedAmount,
        decimal refundedAmount,
        decimal expected) =>
        Assert.Equal(expected, ReportRules.NetRevenue(status, amount, chargedAmount, refundedAmount));

    [Fact]
    public void Guests_are_ranked_by_completed_stays_then_nights()
    {
        var guests = new[]
        {
            Guest(1, "Prvi gost", completed: 2, nights: 4, spent: 500),
            Guest(2, "Drugi gost", completed: 2, nights: 7, spent: 400),
            Guest(3, "Treći gost", completed: 1, nights: 10, spent: 900)
        };

        Assert.Equal([2, 1, 3], ReportRules.RankGuests(guests, 10).Select(x => x.GuestId));
    }

    [Fact]
    public void Guest_ranking_respects_limit()
    {
        var guests = new[] { Guest(1, "A", 1, 2, 100), Guest(2, "B", 2, 4, 200) };

        Assert.Single(ReportRules.RankGuests(guests, 1));
    }

    private static TopGuestDto Guest(int id, string name, int completed, int nights, decimal spent) =>
        new(id, name, $"guest{id}@test.local", null, completed, completed, nights, completed, spent);
}
