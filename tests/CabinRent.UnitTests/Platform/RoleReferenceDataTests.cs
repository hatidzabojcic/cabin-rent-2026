using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using CabinRent.Model.Catalog;
using CabinRent.Services.Exceptions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace CabinRent.UnitTests.Platform;

public sealed class RoleReferenceDataTests
{
    [Fact]
    public async Task Updating_role_display_data_keeps_authorization_code_unchanged()
    {
        await using var fixture = await RoleFixture.CreateAsync();
        var service = new ReferenceDataService(fixture.Context, new ReferenceDataCacheState());
        var created = await service.CreateRoleAsync(new CreateRoleRequest
        {
            Code = "Support",
            Name = "Podrška",
            Description = "Početni opis"
        });

        var updated = await service.UpdateRoleAsync(created.Id, new UpdateRoleRequest
        {
            Name = "Korisnička podrška",
            Description = "Promijenjeni opis"
        });

        Assert.NotNull(updated);
        Assert.Equal("Support", updated.Code);
        Assert.Equal("Korisnička podrška", updated.Name);
        Assert.Equal("Support", (await fixture.Context.Roles.SingleAsync()).Code);
    }

    [Fact]
    public async Task Duplicate_role_code_is_rejected()
    {
        await using var fixture = await RoleFixture.CreateAsync();
        var service = new ReferenceDataService(fixture.Context, new ReferenceDataCacheState());
        await service.CreateRoleAsync(new CreateRoleRequest { Code = "Support", Name = "Podrška" });

        await Assert.ThrowsAsync<BusinessRuleException>(() =>
            service.CreateRoleAsync(new CreateRoleRequest { Code = "Support", Name = "Druga uloga" }));
    }

    [Fact]
    public async Task System_role_cannot_be_deleted_even_when_unassigned()
    {
        await using var fixture = await RoleFixture.CreateAsync();
        fixture.Context.Roles.Add(new Role { Code = SystemRoleCodes.Guest, Name = "Gost" });
        await fixture.Context.SaveChangesAsync();
        var roleId = await fixture.Context.Roles.Select(role => role.Id).SingleAsync();
        var service = new ReferenceDataService(fixture.Context, new ReferenceDataCacheState());

        await Assert.ThrowsAsync<BusinessRuleException>(() => service.DeleteRoleAsync(roleId));
    }

    private sealed class RoleFixture : IAsyncDisposable
    {
        private readonly SqliteConnection _connection;
        public CabinRentDbContext Context { get; }

        private RoleFixture(SqliteConnection connection, CabinRentDbContext context)
        {
            _connection = connection;
            Context = context;
        }

        public static async Task<RoleFixture> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var context = new CabinRentDbContext(new DbContextOptionsBuilder<CabinRentDbContext>()
                .UseSqlite(connection)
                .Options);
            await context.Database.EnsureCreatedAsync();
            return new RoleFixture(connection, context);
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }
    }
}
