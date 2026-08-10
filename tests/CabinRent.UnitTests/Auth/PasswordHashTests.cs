using CabinRent.Infrastructure.Persistence;
using Xunit;

namespace CabinRent.UnitTests.Auth;

public sealed class PasswordHashTests
{
    [Fact]
    public void Create_ProducesVerifiableSaltedHash()
    {
        const string password = "StrongPassword123!";

        var first = PasswordHash.Create(password);
        var second = PasswordHash.Create(password);

        Assert.NotEqual(first, second);
        Assert.True(PasswordHash.Verify(password, first));
        Assert.False(PasswordHash.Verify("WrongPassword", first));
    }
}
