using CabinRent.Infrastructure.Cabins;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Cabins;
using CabinRent.Services.Exceptions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace CabinRent.UnitTests.Cabins;

public sealed class AvailabilityBlockServiceTests
{
    [Fact]
    public async Task Owner_can_create_update_and_delete_block_for_own_cabin()
    {
        await using var fixture = await AvailabilityFixture.CreateAsync();
        var service = new AvailabilityBlockService(fixture.Context);
        var from = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(20);

        var created = await service.CreateAsync(fixture.CabinId,
            Request(from, from.AddDays(2), "Održavanje"), fixture.OwnerId, false);
        var updated = await service.UpdateAsync(fixture.CabinId, created.Id,
            Request(from.AddDays(1), from.AddDays(3), "Privatno korištenje"), fixture.OwnerId, false);
        var deleted = await service.DeleteAsync(fixture.CabinId, created.Id, fixture.OwnerId, false);

        Assert.Equal("Privatno korištenje", updated!.Reason);
        Assert.True(deleted);
        Assert.Empty(await fixture.Context.AvailabilityBlocks.ToListAsync());
    }

    [Fact]
    public async Task Owner_cannot_manage_another_owners_cabin()
    {
        await using var fixture = await AvailabilityFixture.CreateAsync();
        var service = new AvailabilityBlockService(fixture.Context);
        var from = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(20);

        await Assert.ThrowsAsync<ForbiddenOperationException>(() =>
            service.CreateAsync(fixture.CabinId, Request(from, from.AddDays(2), "Održavanje"), 999, false));
    }

    [Fact]
    public async Task Overlapping_availability_blocks_are_rejected()
    {
        await using var fixture = await AvailabilityFixture.CreateAsync();
        var service = new AvailabilityBlockService(fixture.Context);
        var from = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(20);
        await service.CreateAsync(fixture.CabinId,
            Request(from, from.AddDays(3), "Održavanje"), fixture.OwnerId, false);

        await Assert.ThrowsAsync<BusinessRuleException>(() =>
            service.CreateAsync(fixture.CabinId,
                Request(from.AddDays(2), from.AddDays(4), "Privatno"), fixture.OwnerId, false));
    }

    [Fact]
    public async Task Block_overlapping_an_active_reservation_is_rejected()
    {
        await using var fixture = await AvailabilityFixture.CreateAsync();
        var service = new AvailabilityBlockService(fixture.Context);
        var from = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(20);
        fixture.Context.Reservations.Add(new Reservation
        {
            CabinId = fixture.CabinId,
            GuestId = fixture.GuestId,
            CheckIn = from,
            CheckOut = from.AddDays(3),
            Adults = 1,
            PricePerNight = 100,
            TotalPrice = 300,
            Status = ReservationStatus.Confirmed
        });
        await fixture.Context.SaveChangesAsync();

        await Assert.ThrowsAsync<BusinessRuleException>(() =>
            service.CreateAsync(fixture.CabinId,
                Request(from.AddDays(1), from.AddDays(4), "Održavanje"), fixture.OwnerId, false));
    }

    private static SaveAvailabilityBlockRequest Request(DateOnly from, DateOnly to, string reason) =>
        new() { From = from, To = to, Reason = reason };

    private sealed class AvailabilityFixture : IAsyncDisposable
    {
        private readonly SqliteConnection _connection;
        public CabinRentDbContext Context { get; }
        public int OwnerId { get; private set; }
        public int GuestId { get; private set; }
        public int CabinId { get; private set; }

        private AvailabilityFixture(SqliteConnection connection, CabinRentDbContext context)
        {
            _connection = connection;
            Context = context;
        }

        public static async Task<AvailabilityFixture> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var context = new CabinRentDbContext(new DbContextOptionsBuilder<CabinRentDbContext>()
                .UseSqlite(connection).Options);
            await context.Database.EnsureCreatedAsync();
            var fixture = new AvailabilityFixture(connection, context);

            var owner = User("owner");
            var guest = User("guest");
            var country = new Country { Name = "Bosna i Hercegovina", IsoCode = "BA" };
            var city = new City { Name = "Sarajevo", Country = country };
            var type = new CabinType { Name = "Brvnara" };
            var cabin = new Cabin
            {
                Name = "Test vikendica", Description = "Opis", Address = "Adresa",
                AreaSquareMeters = 50, PricePerNight = 100, MaxAdults = 2,
                Bedrooms = 1, Bathrooms = 1, Owner = owner, City = city, CabinType = type
            };
            context.AddRange(owner, guest, cabin);
            await context.SaveChangesAsync();
            fixture.OwnerId = owner.Id;
            fixture.GuestId = guest.Id;
            fixture.CabinId = cabin.Id;
            return fixture;
        }

        private static User User(string name) => new()
        {
            FirstName = name, LastName = "Test", Email = $"{name}@test.local",
            UserName = name, PasswordHash = "hash"
        };

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }
    }
}
