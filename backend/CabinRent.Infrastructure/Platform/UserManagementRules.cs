namespace CabinRent.Infrastructure.Platform;

public static class UserManagementRules
{
    public static bool CanChangeStatus(int targetUserId, bool isActive, int actorId) =>
        targetUserId != actorId || isActive;

    public static bool RequiresSessionInvalidation(
    bool passwordChanged,
    bool roleChanged,
    bool statusChanged) =>
    passwordChanged || roleChanged || statusChanged;    
}
