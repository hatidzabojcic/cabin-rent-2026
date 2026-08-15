using CabinRent.Infrastructure.Cabins;
using Xunit;

namespace CabinRent.UnitTests.Cabins;

public sealed class CabinImageRulesTests
{
    [Theory]
    [InlineData(".jpg", "image/jpeg")]
    [InlineData(".jpeg", "image/jpeg")]
    [InlineData(".png", "image/png")]
    [InlineData(".webp", "image/webp")]
    public void Supported_image_formats_are_accepted(string extension, string contentType) =>
        Assert.True(CabinImageRules.IsSupported(extension, contentType));

    [Theory]
    [InlineData(".exe", "image/jpeg")]
    [InlineData(".jpg", "application/octet-stream")]
    [InlineData(".svg", "image/svg+xml")]
    public void Unsupported_image_formats_are_rejected(string extension, string contentType) =>
        Assert.False(CabinImageRules.IsSupported(extension, contentType));
}
