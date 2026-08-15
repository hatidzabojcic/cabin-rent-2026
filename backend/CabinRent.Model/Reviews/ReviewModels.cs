using System.ComponentModel.DataAnnotations;

namespace CabinRent.Model.Reviews;

public sealed record ReviewDto(
    int Id, int ReservationId, int CabinId, string CabinName, int GuestId,
    string GuestName, string GuestEmail, int Rating, string? Comment, bool IsApproved, DateTime CreatedAtUtc);

public sealed record UpdateReviewApprovalRequest(bool IsApproved);

public sealed class CreateReviewRequest
{
    [Range(1, int.MaxValue)] public int ReservationId { get; init; }
    [Range(1, 5)] public int Rating { get; init; }
    [MaxLength(2000)] public string? Comment { get; init; }
}
