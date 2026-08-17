namespace CabinRent.Infrastructure.Recommendations;

public static class RecommendationRules
{
    public static double Score(
        int similarGuestStays,
        int completedStays,
        double? averageRating,
        int reviewCount,
        bool matchesPreference)
    {
        var score = similarGuestStays * 8d
            + completedStays * 3d
            + (averageRating ?? 0d) * 2d
            + Math.Min(reviewCount, 10) * 0.25d
            + (matchesPreference ? 1d : 0d);
        return Math.Round(score, 2);
    }

    public static string Reason(
        int similarGuestStays,
        int completedStays,
        double? averageRating,
        int reviewCount,
        bool matchesPreference) =>
        similarGuestStays > 0
            ? "Gosti sa sličnim interesovanjima rezervisali su ovu vikendicu."
            : averageRating >= 4.5 && reviewCount > 0
                ? "Visoko je ocijenjena među gostima."
                : completedStays > 0
                    ? "Jedna je od najčešće rezervisanih vikendica."
                    : matchesPreference
                        ? "Slična je vikendicama koje ste ranije odabrali."
                        : "Popularna je među gostima.";
}
