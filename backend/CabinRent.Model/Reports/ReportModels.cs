namespace CabinRent.Model.Reports;

public sealed record AnnualReportDto(
    int Year,
    int TotalReservations,
    int CompletedStays,
    int TotalNights,
    int TotalGuests,
    decimal Revenue,
    IReadOnlyCollection<MonthlyReportDto> Months,
    IReadOnlyCollection<CabinAnnualReportDto> Cabins);

public sealed record MonthlyReportDto(
    int Month, int Reservations, int CompletedStays, int Nights, decimal Revenue);

public sealed record CabinAnnualReportDto(
    int CabinId, string CabinName, string City, string OwnerName,
    int Reservations, int CompletedStays, int Nights, int Guests, decimal Revenue);
