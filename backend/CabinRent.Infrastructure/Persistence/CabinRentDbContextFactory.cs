using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace CabinRent.Infrastructure.Persistence;

public sealed class CabinRentDbContextFactory : IDesignTimeDbContextFactory<CabinRentDbContext>
{
    public CabinRentDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? "Server=localhost,1433;Database=CabinRent;User Id=sa;Password=CabinRent_2026!Dev;TrustServerCertificate=True";

        var options = new DbContextOptionsBuilder<CabinRentDbContext>()
            .UseSqlServer(connectionString)
            .Options;

        return new CabinRentDbContext(options);
    }
}
