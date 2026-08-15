using CabinRent.Services.Cabins;

namespace CabinRent.Infrastructure.Cabins;

public sealed class LocalImageStorage(string rootPath) : IImageStorage
{
    private readonly string _rootPath = Path.GetFullPath(rootPath);

    public async Task<string> SaveAsync(int cabinId, Stream content, string extension, CancellationToken cancellationToken = default)
    {
        var safeExtension = extension.ToLowerInvariant();
        var relativeDirectory = Path.Combine("cabins", cabinId.ToString());
        var directory = Path.Combine(_rootPath, relativeDirectory);
        Directory.CreateDirectory(directory);
        var fileName = $"{Guid.NewGuid():N}{safeExtension}";
        var path = Path.Combine(directory, fileName);
        await using var output = File.Create(path);
        await content.CopyToAsync(output, cancellationToken);
        return $"/uploads/cabins/{cabinId}/{fileName}";
    }

    public Task DeleteAsync(string url, CancellationToken cancellationToken = default)
    {
        const string prefix = "/uploads/";
        if (!url.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) return Task.CompletedTask;
        var relative = url[prefix.Length..].Replace('/', Path.DirectorySeparatorChar);
        var path = Path.GetFullPath(Path.Combine(_rootPath, relative));
        if (!path.StartsWith(_rootPath, StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Putanja slike nije validna.");
        if (File.Exists(path)) File.Delete(path);
        return Task.CompletedTask;
    }
}
