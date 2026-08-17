using CabinRent.Services.Cabins;

namespace CabinRent.Infrastructure.Cabins;

public sealed class LocalImageStorage(string rootPath) : IImageStorage
{
    private readonly string _rootPath = Path.GetFullPath(rootPath);

    public async Task<string> SaveAsync(int cabinId, Stream content, string extension, CancellationToken cancellationToken = default)
        => await SaveAsync(Path.Combine("cabins", cabinId.ToString()), content, extension, cancellationToken);

    public async Task<string> SaveProfileAsync(int userId, Stream content, string extension, CancellationToken cancellationToken = default)
        => await SaveAsync(Path.Combine("profiles", userId.ToString()), content, extension, cancellationToken);

    private async Task<string> SaveAsync(string relativeDirectory, Stream content, string extension, CancellationToken cancellationToken)
    {
        var safeExtension = extension.ToLowerInvariant();
        var directory = Path.Combine(_rootPath, relativeDirectory);
        Directory.CreateDirectory(directory);
        var fileName = $"{Guid.NewGuid():N}{safeExtension}";
        var path = Path.Combine(directory, fileName);
        await using var output = File.Create(path);
        await content.CopyToAsync(output, cancellationToken);
        return $"/uploads/{relativeDirectory.Replace(Path.DirectorySeparatorChar, '/')}/{fileName}";
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
