namespace CabinRent.Infrastructure.Platform;

public static class UserManagementRules
{
    public static bool CanChangeStatus(int targetUserId, bool isActive, int actorId) =>
        targetUserId != actorId || isActive;
}
