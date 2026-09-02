using CabinRent.Infrastructure.Platform;
using Xunit;

namespace CabinRent.UnitTests.Reservations;

public sealed class ReservationCreationRulesTests
{
    [Fact]
    public void Future_check_in_is_valid()
    {
        var result = ReservationCreationRules.IsCheckInInFuture(
            new DateOnly(2026, 9, 3),
            new DateOnly(2026, 9, 2));

        Assert.True(result);
    }

    [Theory]
    [InlineData(2026, 9, 2)]
    [InlineData(2026, 9, 1)]
    public void Today_or_past_check_in_is_invalid(
        int year,
        int month,
        int day)
    {
        var result = ReservationCreationRules.IsCheckInInFuture(
            new DateOnly(year, month, day),
            new DateOnly(2026, 9, 2));

        Assert.False(result);
    }

    [Theory]
    [InlineData(1, 0, true)]
    [InlineData(2, 2, true)]
    [InlineData(0, 0, false)]
    [InlineData(1, -1, false)]
    public void Guest_counts_have_valid_minimums(
        int adults,
        int children,
        bool expected)
    {
        var result = ReservationCreationRules.HasValidGuestCounts(
            adults,
            children);

        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData(2, 4, 2, 4, true)]
    [InlineData(3, 3, 2, 4, false)]
    [InlineData(2, 5, 2, 4, false)]
    [InlineData(6, 0, 2, 4, false)]
    public void Adults_and_children_use_separate_capacity_limits(
        int adults,
        int children,
        int maxAdults,
        int maxChildren,
        bool expected)
    {
        var result = ReservationCreationRules.FitsCabinCapacity(
            adults,
            children,
            maxAdults,
            maxChildren);

        Assert.Equal(expected, result);
    }
}