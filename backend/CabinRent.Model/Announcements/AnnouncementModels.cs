using System.ComponentModel.DataAnnotations;

namespace CabinRent.Model.Announcements;

public sealed record AnnouncementDto(
    int Id, string Title, string Content, string? ImageUrl,
    DateTime PublishedAtUtc, bool IsActive, DateTime CreatedAtUtc);

public sealed class SaveAnnouncementRequest
{
    [Required, MaxLength(200)] public required string Title { get; init; }
    [Required, MaxLength(4000)] public required string Content { get; init; }
    [MaxLength(1000), Url] public string? ImageUrl { get; init; }
    public DateTime PublishedAtUtc { get; init; }
    public bool IsActive { get; init; } = true;
}
