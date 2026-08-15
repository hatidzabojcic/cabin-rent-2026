namespace CabinRent.Model.Notifications;

public sealed record NotificationEvent(
    Guid EventId, int RecipientUserId, string Type, string Title, string Message,
    string? RelatedEntityType, int? RelatedEntityId, DateTime OccurredAtUtc);

public sealed record NotificationDto(
    int Id, string Type, string Title, string Message, string? RelatedEntityType,
    int? RelatedEntityId, bool IsRead, DateTime? ReadAtUtc, DateTime CreatedAtUtc);

public sealed record NotificationSummaryDto(int UnreadCount);
