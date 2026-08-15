using CabinRent.Infrastructure.Platform;
using Xunit;

namespace CabinRent.UnitTests.Reviews;

public sealed class ReviewModerationRulesTests
{
    [Fact]
    public void Administrator_can_manage_any_review() =>
        Assert.True(ReviewModerationRules.CanManage(true, 20, 10));

    [Fact]
    public void Owner_can_manage_review_for_own_cabin() =>
        Assert.True(ReviewModerationRules.CanManage(false, 10, 10));

    [Fact]
    public void Owner_cannot_manage_review_for_another_owners_cabin() =>
        Assert.False(ReviewModerationRules.CanManage(false, 20, 10));
}
