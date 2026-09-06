namespace CabinRent.Infrastructure.Recommendations;

public static class RecommendationRules
{
    public static double Score(
        int similarGuestStays,
        int completedStays,
        double? averageRating,
        int reviewCount,
        bool matchesLocationOrType,
        int matchingAmenities)
    {
        var score = similarGuestStays * 8d
            + completedStays * 3d
            + (averageRating ?? 0d) * 2d
            + Math.Min(reviewCount, 10) * 0.25d
            + (matchesLocationOrType ? 1d : 0d)
            + Math.Min(Math.Max(matchingAmenities, 0), 5) * 1.5d;
        return Math.Round(score, 2);
    }

    public static string Reason(
        int similarGuestStays,
        int completedStays,
        double? averageRating,
        int reviewCount,
        bool matchesLocationOrType,
        int matchingAmenities) =>
        similarGuestStays > 0
            ? "Gosti sa sličnim interesovanjima rezervisali su ovu vikendicu."
            : averageRating >= 4.5 && reviewCount > 0
                ? "Visoko je ocijenjena među gostima."
                : completedStays > 0
                    ? "Jedna je od najčešće rezervisanih vikendica."
                    : matchingAmenities > 0
                        ? "Ima pogodnosti koje ste ranije birali."
                        : matchesLocationOrType
                            ? "Slična je vikendicama koje ste ranije odabrali."
                            : "Popularna je među gostima.";
}
