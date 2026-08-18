using CabinRent.Infrastructure.Payments;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Services.Payments;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace CabinRent.UnitTests.Payments;

public sealed class PaymentWebhookTests
{
    [Fact]
    public async Task Successful_webhook_marks_payment_paid_and_creates_notifications_once()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var gateway = new FakePaymentGateway(new GatewayWebhookEvent(
            "evt_success", "payment_intent.succeeded", "pi_test", 120000, "bam", null));
        var service = new PaymentService(fixture.Context, gateway);

        var first = await service.ProcessWebhookAsync("payload", "signature");
        var second = await service.ProcessWebhookAsync("payload", "signature");

        var payment = await fixture.Context.Payments.SingleAsync();
        Assert.Equal("Paid", first.Outcome);
        Assert.Equal("Duplicate", second.Outcome);
        Assert.Equal(PaymentStatus.Paid, payment.Status);
        Assert.Equal(1200m, payment.ChargedAmount);
        Assert.NotNull(payment.PaidAtUtc);
        Assert.Equal(1, await fixture.Context.PaymentWebhookEvents.CountAsync());
        Assert.Equal(2, await fixture.Context.NotificationOutbox.CountAsync());
    }

    [Fact]
    public async Task Failed_webhook_never_downgrades_paid_payment()
    {
        await using var fixture = await PaymentFixture.CreateAsync(PaymentStatus.Paid);
        var gateway = new FakePaymentGateway(new GatewayWebhookEvent(
            "evt_failed", "payment_intent.payment_failed", "pi_test", 0, "bam", "Kartica je odbijena."));
        var service = new PaymentService(fixture.Context, gateway);

        var result = await service.ProcessWebhookAsync("payload", "signature");

        Assert.Equal("Ignored", result.Outcome);
        Assert.Equal(PaymentStatus.Paid, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.Empty(await fixture.Context.NotificationOutbox.ToListAsync());
    }

    [Fact]
    public async Task Amount_mismatch_is_recorded_without_marking_payment_paid()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var gateway = new FakePaymentGateway(new GatewayWebhookEvent(
            "evt_mismatch", "payment_intent.succeeded", "pi_test", 100, "bam", null));
        var service = new PaymentService(fixture.Context, gateway);

        var result = await service.ProcessWebhookAsync("payload", "signature");

        Assert.Equal("RejectedAmountMismatch", result.Outcome);
        Assert.Equal(PaymentStatus.Pending, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.Empty(await fixture.Context.NotificationOutbox.ToListAsync());
    }

    private sealed class FakePaymentGateway(GatewayWebhookEvent webhook) : IPaymentGateway
    {
        public string PublishableKey => "pk_test_fake";
        public Task<GatewayPaymentIntent> CreateIntentAsync(long amountInMinorUnits, string currency, int reservationId, int paymentId, string idempotencyKey, CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();
        public Task<GatewayPaymentIntent> GetIntentAsync(string providerReference, CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();
        public GatewayWebhookEvent ParseWebhook(string payload, string signature) => webhook;
    }

    private sealed class PaymentFixture : IAsyncDisposable
    {
        private readonly SqliteConnection _connection;
        public CabinRentDbContext Context { get; }

        private PaymentFixture(SqliteConnection connection, CabinRentDbContext context)
        {
            _connection = connection;
            Context = context;
        }

        public static async Task<PaymentFixture> CreateAsync(PaymentStatus status = PaymentStatus.Pending)
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var context = new CabinRentDbContext(new DbContextOptionsBuilder<CabinRentDbContext>()
                .UseSqlite(connection)
                .Options);
            await context.Database.EnsureCreatedAsync();

            var owner = User("Owner", "owner@test.local", "owner");
            var guest = User("Guest", "guest@test.local", "guest");
            var cabin = new Cabin
            {
                Name = "Test cabin",
                Description = "Test",
                Address = "Test 1",
                PricePerNight = 300m,
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
            };
            context.Reservations.Add(new Reservation
            {
                Guest = guest,
                Cabin = cabin,
                CheckIn = new DateOnly(2027, 1, 10),
                CheckOut = new DateOnly(2027, 1, 14),
                Adults = 2,
                PricePerNight = 300m,
                TotalPrice = 1200m,
                Status = ReservationStatus.Confirmed,
                Payment = new Payment
                {
                    Amount = 1200m,
                    ChargedAmount = status == PaymentStatus.Paid ? 1200m : null,
                    Currency = "BAM",
                    Provider = "Stripe",
                    ProviderReference = "pi_test",
                    Status = status,
                    PaidAtUtc = status == PaymentStatus.Paid ? DateTime.UtcNow : null
                }
            });
            await context.SaveChangesAsync();
            return new PaymentFixture(connection, context);
        }

        private static User User(string firstName, string email, string userName) => new()
        {
            FirstName = firstName,
            LastName = "Test",
            Email = email,
            UserName = userName,
            PasswordHash = "test-password-hash"
        };

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await _connection.DisposeAsync();
        }
    }
}
