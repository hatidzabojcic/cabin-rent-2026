namespace CabinRent.Infrastructure.Cabins;

public static class CabinImageRules
{
    public const long MaxFileSize = 8 * 1024 * 1024;
    private static readonly string[] Extensions = [".jpg", ".jpeg", ".png", ".webp"];
    private static readonly string[] ContentTypes = ["image/jpeg", "image/png", "image/webp"];

    public static bool IsSupported(string extension, string contentType) =>
        Extensions.Contains(extension.ToLowerInvariant()) && ContentTypes.Contains(contentType.ToLowerInvariant());
}
