using CabinRent.Model.Cabins;
using Xunit;

namespace CabinRent.UnitTests.Cabins;

public sealed class CabinSearchRequestTests
{
    [Fact]
    public void Defaults_StartAtFirstPageWithTwentyItems()
    {
        var request = new CabinSearchRequest();

        Assert.Equal(1, request.Page);
        Assert.Equal(20, request.PageSize);
    }
}
