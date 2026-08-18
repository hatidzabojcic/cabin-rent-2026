using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Platform;
using CabinRent.Model.Reservations;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace CabinRent.UnitTests.Notifications;

public sealed class NotificationOutboxTests
{
    [Fact]
    public async Task Reservation_status_change_is_saved_with_outbox_message_without_rabbitmq()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();
        await using var context = new CabinRentDbContext(new DbContextOptionsBuilder<CabinRentDbContext>()
            .UseSqlite(connection)
            .Options);
        await context.Database.EnsureCreatedAsync();

        var owner = User("owner", "owner@test.local");
        var guest = User("guest", "guest@test.local");
        var reservation = new Reservation
        {
            Guest = guest,
            Cabin = new Cabin
            {
                Name = "Test cabin",
                Description = "Test",
                Address = "Test 1",
                PricePerNight = 200m,
                MaxAdults = 4,
                MaxChildren = 2,
                Bedrooms = 2,
                Bathrooms = 1,
                Owner = owner,
                City = new City
                {
                    Name = "Sarajevo",
                    Country = new Country { Name = "Bosna i Hercegovina", IsoCode = "BA" }
                },
                CabinType = new CabinType { Name = "Brvnara" }
            },
            CheckIn = new DateOnly(2027, 2, 10),
            CheckOut = new DateOnly(2027, 2, 12),
            Adults = 2,
            PricePerNight = 200m,
            TotalPrice = 400m,
            Status = ReservationStatus.Pending,
            Payment = new Payment
            {
                Amount = 400m,
                Currency = "BAM",
                Provider = "Pending",
                Status = PaymentStatus.Pending
            }
        };
        context.Reservations.Add(reservation);
        await context.SaveChangesAsync();

        var service = new ReservationService(context);
        var result = await service.UpdateStatusAsync(
            reservation.Id,
            new UpdateReservationStatusRequest { Status = "Confirmed" },
            owner.Id,
            isAdmin: false);

        Assert.NotNull(result);
        Assert.Equal("Confirmed", result.Status);
        var message = await context.NotificationOutbox.SingleAsync();
        Assert.Equal(guest.Id, message.RecipientUserId);
        Assert.Equal("ReservationStatusChanged", message.Type);
        Assert.Null(message.PublishedAtUtc);
    }

    private static User User(string userName, string email) => new()
    {
        FirstName = userName,
        LastName = "Test",
        Email = email,
        UserName = userName,
        PasswordHash = "test-password-hash"
    };
}
