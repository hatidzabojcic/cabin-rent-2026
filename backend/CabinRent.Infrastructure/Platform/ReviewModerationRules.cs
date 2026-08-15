namespace CabinRent.Infrastructure.Platform;

public static class ReviewModerationRules
{
    public static bool CanManage(bool isAdmin, int cabinOwnerId, int actorId) =>
        isAdmin || cabinOwnerId == actorId;
}
