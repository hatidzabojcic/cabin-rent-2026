namespace CabinRent.Infrastructure.Cabins;

public static class CabinImageRules
{
    public const long MaxFileSize = 8 * 1024 * 1024;
    private static readonly string[] Extensions = [".jpg", ".jpeg", ".png", ".webp"];
    private static readonly string[] ContentTypes = ["image/jpeg", "image/png", "image/webp"];

    public static bool IsSupported(string extension, string contentType) =>
        Extensions.Contains(extension.ToLowerInvariant()) && ContentTypes.Contains(contentType.ToLowerInvariant());

    public static async Task<bool> HasValidSignatureAsync(
        Stream stream,
        string extension,
        CancellationToken cancellationToken = default)
    {
        var header = new byte[12];
        var read = await stream.ReadAsync(header.AsMemory(0, header.Length), cancellationToken);
        if (stream.CanSeek) stream.Position = 0;
        var normalized = extension.ToLowerInvariant();
        return normalized switch
        {
            ".jpg" or ".jpeg" => read >= 3
                && header[0] == 0xff && header[1] == 0xd8 && header[2] == 0xff,
            ".png" => read >= 8
                && header.AsSpan(0, 8).SequenceEqual(new byte[] { 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a }),
            ".webp" => read >= 12
                && header.AsSpan(0, 4).SequenceEqual("RIFF"u8)
                && header.AsSpan(8, 4).SequenceEqual("WEBP"u8),
            _ => false
        };
    }
}
