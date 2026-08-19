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

    [Theory]
    [InlineData(new byte[] { 0xFF, 0xD8, 0xFF, 0xE0 }, ".jpg", true)]
    [InlineData(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, ".png", true)]
    [InlineData(new byte[] { 0x4D, 0x5A, 0x90, 0x00 }, ".jpg", false)]
    public async Task File_signature_must_match_declared_image_type(byte[] content, string extension, bool expected)
    {
        await using var stream = new MemoryStream(content);

        var actual = await CabinImageRules.HasValidSignatureAsync(stream, extension);

        Assert.Equal(expected, actual);
        Assert.Equal(0, stream.Position);
    }
}
