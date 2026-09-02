using CabinRent.Infrastructure.Platform;
using Xunit;

namespace CabinRent.UnitTests.Users;

public sealed class UserManagementRulesTests
{
    [Theory]
    [InlineData(true, false, false)]
    [InlineData(false, true, false)]
    [InlineData(false, false, true)]
    [InlineData(true, true, true)]
    public void Security_sensitive_change_requires_session_invalidation(
        bool passwordChanged,
        bool roleChanged,
        bool statusChanged)
    {
        Assert.True(
            UserManagementRules.RequiresSessionInvalidation(
                passwordChanged,
                roleChanged,
                statusChanged));
    }

    [Fact]
    public void Non_security_profile_change_does_not_require_session_invalidation()
    {
        Assert.False(
            UserManagementRules.RequiresSessionInvalidation(
                passwordChanged: false,
                roleChanged: false,
                statusChanged: false));
    }
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
