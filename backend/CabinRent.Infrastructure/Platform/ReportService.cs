using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Reports;
using CabinRent.Services.Platform;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Platform;

public sealed class ReportService(CabinRentDbContext dbContext) : IReportService
{
    public async Task<AnnualReportDto> GetAnnualAsync(int year, int? ownerId, int? cabinId, CancellationToken cancellationToken = default)
    {
        if (!ReportRules.IsValidYear(year)) throw new ArgumentException("Godina mora biti između 2000. i 2100.");

        var cabinsQuery = dbContext.Cabins.AsNoTracking().AsQueryable();
        if (ownerId.HasValue) cabinsQuery = cabinsQuery.Where(x => x.OwnerId == ownerId);
        if (cabinId.HasValue) cabinsQuery = cabinsQuery.Where(x => x.Id == cabinId);
        var cabins = await cabinsQuery
            .Select(x => new { x.Id, x.Name, City = x.City.Name, OwnerName = x.Owner.FirstName + " " + x.Owner.LastName })
            .OrderBy(x => x.Name).ToListAsync(cancellationToken);

        var cabinIds = cabins.Select(x => x.Id).ToArray();
        var reservations = await dbContext.Reservations.AsNoTracking()
            .Where(x => cabinIds.Contains(x.CabinId) && x.CheckIn.Year == year &&
                (x.Status == ReservationStatus.Confirmed || x.Status == ReservationStatus.Completed))
            .Select(x => new ReservationReportData(x.CabinId, x.CheckIn, x.CheckOut, x.Adults, x.Children, x.TotalPrice, x.Status))
            .ToListAsync(cancellationToken);

        var cabinReports = cabins.Select(cabin =>
        {
            var items = reservations.Where(x => x.CabinId == cabin.Id).ToList();
            var completed = items.Where(x => x.Status == ReservationStatus.Completed).ToList();
            return new CabinAnnualReportDto(cabin.Id, cabin.Name, cabin.City, cabin.OwnerName,
                items.Count, completed.Count, items.Sum(Nights), items.Sum(x => x.Adults + x.Children), completed.Sum(x => x.TotalPrice));
        }).OrderByDescending(x => x.CompletedStays).ThenByDescending(x => x.Nights).ThenBy(x => x.CabinName).ToList();

        var months = Enumerable.Range(1, 12).Select(month =>
        {
            var items = reservations.Where(x => x.CheckIn.Month == month).ToList();
            var completed = items.Where(x => x.Status == ReservationStatus.Completed).ToList();
            return new MonthlyReportDto(month, items.Count, completed.Count, items.Sum(Nights), completed.Sum(x => x.TotalPrice));
        }).ToList();

        var completedReservations = reservations.Where(x => x.Status == ReservationStatus.Completed).ToList();
        return new AnnualReportDto(year, reservations.Count, completedReservations.Count, reservations.Sum(Nights),
            reservations.Sum(x => x.Adults + x.Children), completedReservations.Sum(x => x.TotalPrice), months, cabinReports);
    }

    private static int Nights(ReservationReportData reservation) =>
        ReportRules.Nights(reservation.CheckIn, reservation.CheckOut);

    private sealed record ReservationReportData(
        int CabinId, DateOnly CheckIn, DateOnly CheckOut, int Adults, int Children,
        decimal TotalPrice, ReservationStatus Status);
}
