using CabinRent.Infrastructure.Platform;
using Xunit;

namespace CabinRent.UnitTests.Users;

public sealed class UserManagementRulesTests
{
    [Fact]
    public void Administrator_cannot_deactivate_own_account() =>
        Assert.False(UserManagementRules.CanChangeStatus(5, false, 5));

    [Fact]
    public void Administrator_can_activate_own_account() =>
        Assert.True(UserManagementRules.CanChangeStatus(5, true, 5));

    [Theory]
    [InlineData(true)]
    [InlineData(false)]
    public void Administrator_can_change_another_users_status(bool isActive) =>
        Assert.True(UserManagementRules.CanChangeStatus(6, isActive, 5));
}
