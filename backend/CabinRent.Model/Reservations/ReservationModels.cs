using System.ComponentModel.DataAnnotations;

namespace CabinRent.Model.Reservations;

public sealed record ReservationDto(
    int Id, string ConfirmationCode, int CabinId, string CabinName, int OwnerId, int GuestId, string GuestName,
    string GuestEmail, string? GuestPhoneNumber,
    DateOnly CheckIn, DateOnly CheckOut, int Adults, int Children, decimal PricePerNight,
    decimal TotalPrice, string Status, string? SpecialRequests, string? PaymentStatus, DateTime CreatedAtUtc);

public sealed class CreateReservationRequest
{
    [Range(1, int.MaxValue)] public int CabinId { get; init; }
    public DateOnly CheckIn { get; init; }
    public DateOnly CheckOut { get; init; }
    [Range(1, 30)] public int Adults { get; init; }
    [Range(0, 30)] public int Children { get; init; }
    [MaxLength(1000)] public string? SpecialRequests { get; init; }
}

public sealed class UpdateReservationStatusRequest
{
    [Required] public required string Status { get; init; }
}
