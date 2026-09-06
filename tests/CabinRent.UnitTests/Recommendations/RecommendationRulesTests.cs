using CabinRent.Infrastructure.Recommendations;
using Xunit;

namespace CabinRent.UnitTests.Recommendations;

public sealed class RecommendationRulesTests
{
    [Fact]
    public void Collaborative_activity_has_strongest_influence()
    {
        var collaborative = RecommendationRules.Score(2, 0, 4, 1, false, 0);
        var popular = RecommendationRules.Score(0, 3, 5, 5, false, 0);

        Assert.True(collaborative > popular);
    }

    [Fact]
    public void Matching_preference_increases_score()
    {
        var regular = RecommendationRules.Score(0, 1, 4.5, 2, false, 0);
        var matching = RecommendationRules.Score(0, 1, 4.5, 2, true, 0);

        Assert.Equal(1, matching - regular);
    }

    [Fact]
    public void Collaborative_reason_has_priority() =>
        Assert.StartsWith("Gosti sa sličnim interesovanjima", RecommendationRules.Reason(1, 3, 5, 10, true, 2));

    [Fact]
    public void Highly_rated_fallback_has_clear_reason() =>
        Assert.Equal("Visoko je ocijenjena među gostima.", RecommendationRules.Reason(0, 2, 4.8, 3, false, 0));

    [Fact]
    public void Reservation_popularity_has_priority_over_content_similarity()
    {
        var popular = RecommendationRules.Score(0, 2, null, 0, false, 0);
        var contentMatchOnly = RecommendationRules.Score(0, 0, null, 0, true, 0);

        Assert.True(popular > contentMatchOnly);
    }

    [Fact]
    public void Matching_amenities_increase_score()
    {
        var regular = RecommendationRules.Score(0, 0, null, 0, false, 0);
        var matching = RecommendationRules.Score(0, 0, null, 0, false, 3);

        Assert.Equal(4.5, matching - regular);
    }

    [Fact]
    public void Amenity_match_has_clear_reason() =>
        Assert.Equal("Ima pogodnosti koje ste ranije birali.",
            RecommendationRules.Reason(0, 0, null, 0, false, 1));
}
