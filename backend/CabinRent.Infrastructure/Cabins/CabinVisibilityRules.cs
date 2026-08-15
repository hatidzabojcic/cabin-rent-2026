using System.Linq.Expressions;
using CabinRent.Infrastructure.Persistence;

namespace CabinRent.Infrastructure.Cabins;

public static class CabinVisibilityRules
{
    public static Expression<Func<Cabin, bool>> PubliclyVisible =>
        cabin => cabin.IsActive && cabin.Owner.IsActive;

    public static bool IsPubliclyVisible(bool cabinIsActive, bool ownerIsActive) =>
        cabinIsActive && ownerIsActive;
}
