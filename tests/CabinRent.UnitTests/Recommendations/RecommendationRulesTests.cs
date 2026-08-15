using CabinRent.Infrastructure.Recommendations;
using Xunit;

namespace CabinRent.UnitTests.Recommendations;

public sealed class RecommendationRulesTests
{
    [Fact]
    public void Collaborative_activity_has_strongest_influence()
    {
        var collaborative = RecommendationRules.Score(2, 0, 4, 1, 0, false);
        var popular = RecommendationRules.Score(0, 3, 5, 5, 3, false);

        Assert.True(collaborative > popular);
    }

    [Fact]
    public void Matching_preference_increases_score()
    {
        var regular = RecommendationRules.Score(0, 1, 4.5, 2, 1, false);
        var matching = RecommendationRules.Score(0, 1, 4.5, 2, 1, true);

        Assert.Equal(3, matching - regular);
    }

    [Fact]
    public void Collaborative_reason_has_priority() =>
        Assert.StartsWith("Gosti sa sličnim interesovanjima", RecommendationRules.Reason(1, true, 5, 10));

    [Fact]
    public void Highly_rated_fallback_has_clear_reason() =>
        Assert.Equal("Visoko je ocijenjena među gostima.", RecommendationRules.Reason(0, false, 4.8, 3));
}
