using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Reports;
using CabinRent.Services.Platform;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Platform;

public sealed class ReportService(CabinRentDbContext dbContext) : IReportService
{
    public async Task<AnnualReportDto> GetAnnualAsync(int year, int? ownerId, int? cabinId, CancellationToken cancellationToken = default)
    {
        if (!ReportRules.IsValidYear(year)) throw new RequestValidationException("Godina mora biti između 2000. i 2100.");

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
            .Select(x => new ReservationReportData(
                x.CabinId,
                x.CheckIn,
                x.CheckOut,
                x.Adults,
                x.Children,
                x.Status,
                x.Payment == null ? null : x.Payment.Status,
                x.Payment == null ? 0 : x.Payment.Amount,
                x.Payment == null ? null : x.Payment.ChargedAmount,
                x.Payment == null ? 0 : x.Payment.RefundedAmount))
            .ToListAsync(cancellationToken);

        var cabinReports = cabins.Select(cabin =>
        {
            var items = reservations.Where(x => x.CabinId == cabin.Id).ToList();
            var completed = items.Where(x => x.Status == ReservationStatus.Completed).ToList();
            return new CabinAnnualReportDto(cabin.Id, cabin.Name, cabin.City, cabin.OwnerName,
                items.Count, completed.Count, completed.Sum(Nights), completed.Sum(x => x.Adults + x.Children), completed.Sum(NetRevenue));
        }).OrderByDescending(x => x.CompletedStays).ThenByDescending(x => x.Nights).ThenBy(x => x.CabinName).ToList();

        var months = Enumerable.Range(1, 12).Select(month =>
        {
            var items = reservations.Where(x => x.CheckIn.Month == month).ToList();
            var completed = items.Where(x => x.Status == ReservationStatus.Completed).ToList();
            return new MonthlyReportDto(month, items.Count, completed.Count, completed.Sum(Nights), completed.Sum(NetRevenue));
        }).ToList();

        var completedReservations = reservations.Where(x => x.Status == ReservationStatus.Completed).ToList();
        return new AnnualReportDto(year, reservations.Count, completedReservations.Count, completedReservations.Sum(Nights),
            completedReservations.Sum(x => x.Adults + x.Children), completedReservations.Sum(NetRevenue), months, cabinReports);
    }

    public async Task<TopGuestsReportDto> GetTopGuestsAsync(
        int year, int? cabinId, int limit, CancellationToken cancellationToken = default)
    {
        if (!ReportRules.IsValidYear(year)) throw new RequestValidationException("Godina mora biti između 2000. i 2100.");
        if (cabinId.HasValue && !await dbContext.Cabins.AnyAsync(x => x.Id == cabinId.Value, cancellationToken))
            throw new ResourceNotFoundException("Vikendica nije pronađena.");

        var query = dbContext.Reservations.AsNoTracking()
            .Where(x => x.CheckIn.Year == year
                && (x.Status == ReservationStatus.Confirmed || x.Status == ReservationStatus.Completed));
        if (cabinId.HasValue) query = query.Where(x => x.CabinId == cabinId.Value);

        var reservations = await query
            .Select(x => new GuestReservationReportData(
                x.GuestId,
                x.Guest.FirstName + " " + x.Guest.LastName,
                x.Guest.Email,
                x.Guest.PhoneNumber,
                x.CabinId,
                x.CheckIn,
                x.CheckOut,
                x.Status,
                x.Payment == null ? null : x.Payment.Status,
                x.Payment == null ? 0 : x.Payment.Amount,
                x.Payment == null ? null : x.Payment.ChargedAmount,
                x.Payment == null ? 0 : x.Payment.RefundedAmount))
            .ToListAsync(cancellationToken);

        var guests = reservations.GroupBy(x => new { x.GuestId, x.GuestName, x.Email, x.PhoneNumber })
            .Select(group =>
            {
                var completed = group.Where(x => x.Status == ReservationStatus.Completed).ToList();
                return new TopGuestDto(
                    group.Key.GuestId,
                    group.Key.GuestName,
                    group.Key.Email,
                    group.Key.PhoneNumber,
                    group.Count(),
                    completed.Count,
                    completed.Sum(x => ReportRules.Nights(x.CheckIn, x.CheckOut)),
                    completed.Select(x => x.CabinId).Distinct().Count(),
                    completed.Sum(NetRevenue));
            });

        return new TopGuestsReportDto(year, cabinId, ReportRules.RankGuests(guests, limit));
    }

    private static int Nights(ReservationReportData reservation) =>
        ReportRules.Nights(reservation.CheckIn, reservation.CheckOut);

    private static decimal NetRevenue(ReservationReportData reservation) =>
        ReportRules.NetRevenue(reservation.PaymentStatus, reservation.PaymentAmount,
            reservation.ChargedAmount, reservation.RefundedAmount);

    private static decimal NetRevenue(GuestReservationReportData reservation) =>
        ReportRules.NetRevenue(reservation.PaymentStatus, reservation.PaymentAmount,
            reservation.ChargedAmount, reservation.RefundedAmount);

    private sealed record ReservationReportData(
        int CabinId, DateOnly CheckIn, DateOnly CheckOut, int Adults, int Children,
        ReservationStatus Status, PaymentStatus? PaymentStatus, decimal PaymentAmount,
        decimal? ChargedAmount, decimal RefundedAmount);

    private sealed record GuestReservationReportData(
        int GuestId, string GuestName, string Email, string? PhoneNumber,
        int CabinId, DateOnly CheckIn, DateOnly CheckOut, ReservationStatus Status,
        PaymentStatus? PaymentStatus, decimal PaymentAmount, decimal? ChargedAmount,
        decimal RefundedAmount);
}
