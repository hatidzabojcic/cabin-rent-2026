using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Cabins;
using CabinRent.Services.Cabins;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Cabins;

public sealed class CabinImageService(CabinRentDbContext dbContext, IImageStorage storage) : ICabinImageService
{
    public async Task<CabinImageDto> AddAsync(int cabinId, Stream content, string extension, string? altText, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var cabin = await ManagedCabin(cabinId, actorId, isAdmin).Include(x => x.Images).SingleOrDefaultAsync(cancellationToken)
            ?? throw new ResourceNotFoundException("Vikendica nije pronađena.");
        if (cabin.Images.Count >= 12) throw new BusinessRuleException("Vikendica može imati najviše 12 slika.");
        var url = await storage.SaveAsync(cabinId, content, extension, cancellationToken);
        try
        {
            var image = new CabinImage
            {
                Cabin = cabin, Url = url, AltText = string.IsNullOrWhiteSpace(altText) ? cabin.Name : altText.Trim(),
                SortOrder = cabin.Images.Count == 0 ? 0 : cabin.Images.Max(x => x.SortOrder) + 1,
                IsCover = cabin.Images.Count == 0
            };
            dbContext.CabinImages.Add(image);
            await dbContext.SaveChangesAsync(cancellationToken);
            return ToDto(image);
        }
        catch
        {
            await storage.DeleteAsync(url, cancellationToken);
            throw;
        }
    }

    public async Task<CabinImageDto?> UpdateAsync(int cabinId, int imageId, UpdateCabinImageRequest request, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var cabin = await ManagedCabin(cabinId, actorId, isAdmin).Include(x => x.Images).SingleOrDefaultAsync(cancellationToken);
        if (cabin is null) return null;
        var image = cabin.Images.SingleOrDefault(x => x.Id == imageId);
        if (image is null) return null;
        if (request.IsCover)
            foreach (var item in cabin.Images) item.IsCover = item.Id == imageId;
        else if (image.IsCover && cabin.Images.Count > 1)
            throw new BusinessRuleException("Prvo odaberite drugu naslovnu sliku.");
        image.AltText = string.IsNullOrWhiteSpace(request.AltText) ? cabin.Name : request.AltText.Trim();
        image.SortOrder = request.SortOrder;
        image.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return ToDto(image);
    }

    public async Task<bool> DeleteAsync(int cabinId, int imageId, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        var cabin = await ManagedCabin(cabinId, actorId, isAdmin).Include(x => x.Images).SingleOrDefaultAsync(cancellationToken);
        if (cabin is null) return false;
        var image = cabin.Images.SingleOrDefault(x => x.Id == imageId);
        if (image is null) return false;
        var wasCover = image.IsCover;
        dbContext.CabinImages.Remove(image);
        if (wasCover)
        {
            var replacement = cabin.Images.Where(x => x.Id != imageId).OrderBy(x => x.SortOrder).FirstOrDefault();
            if (replacement is not null) replacement.IsCover = true;
        }
        await dbContext.SaveChangesAsync(cancellationToken);
        await storage.DeleteAsync(image.Url, cancellationToken);
        return true;
    }

    private IQueryable<Cabin> ManagedCabin(int cabinId, int actorId, bool isAdmin) =>
        dbContext.Cabins.Where(x => x.Id == cabinId && (isAdmin || x.OwnerId == actorId));

    private static CabinImageDto ToDto(CabinImage image) =>
        new(image.Id, image.Url, image.AltText, image.SortOrder, image.IsCover);
}
