namespace CabinRent.Infrastructure.Recommendations;

public static class RecommendationRules
{
    public static double Score(
        int similarGuestStays,
        int completedStays,
        double? averageRating,
        int reviewCount,
        int favoriteCount,
        bool matchesPreference)
    {
        var score = similarGuestStays * 5d
            + completedStays * 1.5d
            + favoriteCount * 0.5d
            + (averageRating ?? 0d) * 2d
            + Math.Min(reviewCount, 10) * 0.2d
            + (matchesPreference ? 3d : 0d);
        return Math.Round(score, 2);
    }

    public static string Reason(
        int similarGuestStays,
        bool matchesPreference,
        double? averageRating,
        int reviewCount) =>
        similarGuestStays > 0
            ? "Gosti sa sličnim interesovanjima rezervisali su ovu vikendicu."
            : matchesPreference
                ? "Slično je vikendicama koje ste ranije odabrali."
                : averageRating >= 4.5 && reviewCount > 0
                    ? "Visoko je ocijenjena među gostima."
                    : "Popularna je među gostima.";
}
