using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace CabinRent.Infrastructure.Persistence;

public sealed class CabinRentDbContextFactory : IDesignTimeDbContextFactory<CabinRentDbContext>
{
    public CabinRentDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? throw new InvalidOperationException(
                "ConnectionStrings__DefaultConnection environment variable is required for design-time operations.");

        var options = new DbContextOptionsBuilder<CabinRentDbContext>()
            .UseSqlServer(connectionString)
            .Options;

        return new CabinRentDbContext(options);
    }
}
