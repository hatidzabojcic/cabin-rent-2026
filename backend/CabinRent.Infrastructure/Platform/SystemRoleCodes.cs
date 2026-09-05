namespace CabinRent.Infrastructure.Platform;

public static class SystemRoleCodes
{
    public const string Admin = "Admin";
    public const string Owner = "Owner";
    public const string Guest = "Guest";

    public static IReadOnlySet<string> All { get; } =
        new HashSet<string>([Admin, Owner, Guest], StringComparer.OrdinalIgnoreCase);
}
