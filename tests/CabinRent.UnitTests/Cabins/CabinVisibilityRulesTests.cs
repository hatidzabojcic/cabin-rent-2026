using CabinRent.Infrastructure.Cabins;
using Xunit;

namespace CabinRent.UnitTests.Cabins;

public sealed class CabinVisibilityRulesTests
{
    [Fact]
    public void Active_cabin_of_active_owner_is_publicly_visible() =>
        Assert.True(CabinVisibilityRules.IsPubliclyVisible(true, true));

    [Theory]
    [InlineData(false, true)]
    [InlineData(true, false)]
    [InlineData(false, false)]
    public void Inactive_cabin_or_owner_hides_cabin(bool cabinIsActive, bool ownerIsActive) =>
        Assert.False(CabinVisibilityRules.IsPubliclyVisible(cabinIsActive, ownerIsActive));
}
