using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Cabins;
using CabinRent.Services.Cabins;
using CabinRent.Services.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Cabins;

public sealed class AvailabilityBlockService(CabinRentDbContext dbContext) : IAvailabilityBlockService
{
    public async Task<IReadOnlyCollection<AvailabilityBlockDto>> GetAsync(
        int cabinId, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        await EnsureCanManageAsync(cabinId, actorId, isAdmin, cancellationToken);
        return await dbContext.AvailabilityBlocks.AsNoTracking()
            .Where(x => x.CabinId == cabinId)
            .OrderBy(x => x.From)
            .Select(x => new AvailabilityBlockDto(x.Id, x.CabinId, x.From, x.To, x.Reason ?? string.Empty))
            .ToListAsync(cancellationToken);
    }

    public async Task<AvailabilityBlockDto> CreateAsync(
        int cabinId, SaveAvailabilityBlockRequest request, int actorId, bool isAdmin,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanManageAsync(cabinId, actorId, isAdmin, cancellationToken);
        await ValidateAsync(cabinId, request, null, cancellationToken);
        var block = new AvailabilityBlock
        {
            CabinId = cabinId,
            From = request.From,
            To = request.To,
            Reason = request.Reason.Trim()
        };
        dbContext.AvailabilityBlocks.Add(block);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(block);
    }

    public async Task<AvailabilityBlockDto?> UpdateAsync(
        int cabinId, int id, SaveAvailabilityBlockRequest request, int actorId, bool isAdmin,
        CancellationToken cancellationToken = default)
    {
        await EnsureCanManageAsync(cabinId, actorId, isAdmin, cancellationToken);
        var block = await dbContext.AvailabilityBlocks
            .SingleOrDefaultAsync(x => x.Id == id && x.CabinId == cabinId, cancellationToken);
        if (block is null) return null;

        await ValidateAsync(cabinId, request, id, cancellationToken);
        block.From = request.From;
        block.To = request.To;
        block.Reason = request.Reason.Trim();
        block.UpdatedAtUtc = DateTime.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        return Map(block);
    }

    public async Task<bool> DeleteAsync(
        int cabinId, int id, int actorId, bool isAdmin, CancellationToken cancellationToken = default)
    {
        await EnsureCanManageAsync(cabinId, actorId, isAdmin, cancellationToken);
        var block = await dbContext.AvailabilityBlocks
            .SingleOrDefaultAsync(x => x.Id == id && x.CabinId == cabinId, cancellationToken);
        if (block is null) return false;
        dbContext.AvailabilityBlocks.Remove(block);
        await dbContext.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task EnsureCanManageAsync(int cabinId, int actorId, bool isAdmin, CancellationToken cancellationToken)
    {
        var exists = await dbContext.Cabins.AnyAsync(
            x => x.Id == cabinId && (isAdmin || x.OwnerId == actorId), cancellationToken);
        if (!exists)
            throw new ForbiddenOperationException("Nemate pristup blokiranim terminima ove vikendice.");
    }

    private async Task ValidateAsync(
        int cabinId, SaveAvailabilityBlockRequest request, int? ignoredBlockId,
        CancellationToken cancellationToken)
    {
        if (request.From < DateOnly.FromDateTime(DateTime.UtcNow))
            throw new RequestValidationException("Početak blokiranog termina ne može biti u prošlosti.");
        if (request.To <= request.From)
            throw new RequestValidationException("Kraj blokiranog termina mora biti nakon početka.");
        if (string.IsNullOrWhiteSpace(request.Reason) || request.Reason.Trim().Length < 3)
            throw new RequestValidationException("Razlog blokiranja mora sadržavati najmanje 3 znaka.");

        var overlapsBlock = await dbContext.AvailabilityBlocks.AnyAsync(x =>
            x.CabinId == cabinId && x.Id != ignoredBlockId &&
            request.From < x.To && request.To > x.From, cancellationToken);
        if (overlapsBlock)
            throw new BusinessRuleException("Odabrani termin se preklapa sa postojećim blokiranim terminom.");

        var overlapsReservation = await dbContext.Reservations.AnyAsync(x =>
            x.CabinId == cabinId &&
            x.Status != ReservationStatus.Cancelled && x.Status != ReservationStatus.Rejected &&
            request.From < x.CheckOut && request.To > x.CheckIn, cancellationToken);
        if (overlapsReservation)
            throw new BusinessRuleException("Odabrani termin se preklapa sa postojećom rezervacijom.");
    }

    private static AvailabilityBlockDto Map(AvailabilityBlock block) =>
        new(block.Id, block.CabinId, block.From, block.To, block.Reason ?? string.Empty);
}
