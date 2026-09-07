using CabinRent.Infrastructure.Payments;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Services.Payments;
using CabinRent.Services.Exceptions;
using CabinRent.Infrastructure.Platform;
using CabinRent.Model.Reservations;
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

    [Fact]
    public async Task Server_confirmation_marks_succeeded_intent_as_paid_without_webhook()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "succeeded", 120000, 120000, "bam"));
        var service = new PaymentService(fixture.Context, gateway);
        var reservation = await fixture.Context.Reservations.SingleAsync();

        var result = await service.ConfirmIntentAsync(reservation.Id, reservation.GuestId);

        Assert.Equal("Paid", result.Status);
        Assert.Equal(1200m, result.PaidAmount);
        Assert.Equal(PaymentStatus.Paid, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.Equal(2, await fixture.Context.NotificationOutbox.CountAsync());
    }

    [Fact]
    public async Task Canceling_paid_reservation_refunds_charged_amount_once()
    {
        await using var fixture = await PaymentFixture.CreateAsync(PaymentStatus.Paid);
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "succeeded", 120000, 120000, "bam"),
            refund: new GatewayRefund("re_test", "succeeded", 120000, "bam"));
        var service = new PaymentService(fixture.Context, gateway);
        var reservation = await fixture.Context.Reservations.SingleAsync();

        const string reason = "Promijenjeni planovi putovanja.";
        Assert.True(await service.CancelReservationAsync(reservation.Id, reservation.GuestId, false, false, reason));
        Assert.True(await service.CancelReservationAsync(reservation.Id, reservation.GuestId, false, false, reason));

        var payment = await fixture.Context.Payments.SingleAsync();
        var cancelledReservation = await fixture.Context.Reservations.SingleAsync();
        Assert.Equal(ReservationStatus.Cancelled, cancelledReservation.Status);
        Assert.Equal(reason, cancelledReservation.StatusChangeReason);
        Assert.Equal(PaymentStatus.Refunded, payment.Status);
        Assert.Equal(1200m, payment.RefundedAmount);
        Assert.Equal("re_test", payment.RefundReference);
        Assert.Equal(1, gateway.RefundCalls);
        Assert.Equal(2, await fixture.Context.NotificationOutbox.CountAsync());
    }

    [Fact]
    public async Task Canceling_unpaid_reservation_cancels_active_intent_before_local_cancellation()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "requires_payment_method", 120000, 0, "bam"),
            cancelledIntent: new GatewayPaymentIntent("pi_test", "secret", "canceled", 120000, 0, "bam"));
        var service = new PaymentService(fixture.Context, gateway);
        var reservation = await fixture.Context.Reservations.SingleAsync();

        Assert.True(await service.CancelReservationAsync(
            reservation.Id, reservation.GuestId, false, false, "Promijenjeni planovi."));

        Assert.Equal(1, gateway.CancelCalls);
        Assert.Equal(ReservationStatus.Cancelled, (await fixture.Context.Reservations.SingleAsync()).Status);
        Assert.Equal(PaymentStatus.Failed, (await fixture.Context.Payments.SingleAsync()).Status);
    }

    [Fact]
    public async Task Pending_refund_is_not_reported_as_completed_refund()
    {
        await using var fixture = await PaymentFixture.CreateAsync(PaymentStatus.Paid);
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "succeeded", 120000, 120000, "bam"),
            refund: new GatewayRefund("re_pending", "pending", 120000, "bam"));
        var service = new PaymentService(fixture.Context, gateway);
        var reservation = await fixture.Context.Reservations.SingleAsync();

        await service.CancelReservationAsync(
            reservation.Id, reservation.GuestId, false, false, "Promijenjeni planovi.");

        var payment = await fixture.Context.Payments.SingleAsync();
        Assert.Equal(PaymentStatus.RefundPending, payment.Status);
        Assert.Null(payment.RefundedAtUtc);
    }

    [Fact]
    public async Task Refund_webhook_finalizes_pending_refund()
    {
        await using var fixture = await PaymentFixture.CreateAsync(PaymentStatus.Paid);
        var payment = await fixture.Context.Payments.SingleAsync();
        payment.Status = PaymentStatus.RefundPending;
        payment.RefundReference = "re_pending";
        payment.RefundedAmount = 1200m;
        await fixture.Context.SaveChangesAsync();
        var gateway = new FakePaymentGateway(webhook: new GatewayWebhookEvent(
            "evt_refund", "refund.updated", "pi_test", 120000, "bam", null,
            "re_pending", "succeeded"));

        var result = await new PaymentService(fixture.Context, gateway)
            .ProcessWebhookAsync("payload", "signature");

        Assert.Equal("Refunded", result.Outcome);
        Assert.Equal(PaymentStatus.Refunded, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.NotNull((await fixture.Context.Payments.SingleAsync()).RefundedAtUtc);
    }

    [Fact]
    public async Task Reconciliation_finalizes_pending_refund_without_webhook_listener()
    {
        await using var fixture = await PaymentFixture.CreateAsync(PaymentStatus.RefundPending);
        var payment = await fixture.Context.Payments.SingleAsync();
        payment.RefundReference = "re_pending";
        payment.RefundedAmount = 1200m;
        await fixture.Context.SaveChangesAsync();
        var gateway = new FakePaymentGateway(
            retrievedRefund: new GatewayRefund("re_pending", "succeeded", 120000, "bam"));

        var changed = await new PaymentService(fixture.Context, gateway).ReconcilePendingAsync();

        Assert.Equal(1, changed);
        Assert.Equal(PaymentStatus.Refunded, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.NotNull((await fixture.Context.Payments.SingleAsync()).RefundedAtUtc);
    }

    [Fact]
    public async Task Reconciliation_records_failed_refund_without_webhook_listener()
    {
        await using var fixture = await PaymentFixture.CreateAsync(PaymentStatus.RefundPending);
        var payment = await fixture.Context.Payments.SingleAsync();
        payment.RefundReference = "re_failed";
        payment.RefundedAmount = 1200m;
        await fixture.Context.SaveChangesAsync();
        var gateway = new FakePaymentGateway(
            retrievedRefund: new GatewayRefund("re_failed", "failed", 120000, "bam"));

        var changed = await new PaymentService(fixture.Context, gateway).ReconcilePendingAsync();

        Assert.Equal(1, changed);
        payment = await fixture.Context.Payments.SingleAsync();
        Assert.Equal(PaymentStatus.RefundFailed, payment.Status);
        Assert.Null(payment.RefundedAtUtc);
    }

    [Fact]
    public async Task Reconciliation_records_successful_payment_when_client_did_not_confirm()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "succeeded", 120000, 120000, "bam"));

        var changed = await new PaymentService(fixture.Context, gateway).ReconcilePendingAsync();

        Assert.Equal(1, changed);
        var payment = await fixture.Context.Payments.SingleAsync();
        Assert.Equal(PaymentStatus.Paid, payment.Status);
        Assert.Equal(1200m, payment.ChargedAmount);
    }

    [Fact]
    public async Task Reconciliation_refunds_late_success_for_cancelled_reservation_without_webhook()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var reservation = await fixture.Context.Reservations.SingleAsync();
        reservation.Status = ReservationStatus.Cancelled;
        await fixture.Context.SaveChangesAsync();
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "succeeded", 120000, 120000, "bam"),
            refund: new GatewayRefund("re_late", "succeeded", 120000, "bam"));
        var service = new PaymentService(fixture.Context, gateway);

        Assert.Equal(1, await service.ReconcilePendingAsync());
        Assert.Equal(0, await service.ReconcilePendingAsync());

        Assert.Equal(PaymentStatus.Refunded, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.Equal(1, gateway.RefundCalls);
    }

    [Fact]
    public async Task Late_success_for_cancelled_reservation_is_automatically_refunded()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var reservation = await fixture.Context.Reservations.SingleAsync();
        reservation.Status = ReservationStatus.Cancelled;
        await fixture.Context.SaveChangesAsync();
        var gateway = new FakePaymentGateway(
            webhook: new GatewayWebhookEvent(
                "evt_late", "payment_intent.succeeded", "pi_test", 120000, "bam", null),
            refund: new GatewayRefund("re_late", "succeeded", 120000, "bam"));

        var result = await new PaymentService(fixture.Context, gateway)
            .ProcessWebhookAsync("payload", "signature");

        Assert.Equal("RefundedAfterCancellation", result.Outcome);
        Assert.Equal(PaymentStatus.Refunded, (await fixture.Context.Payments.SingleAsync()).Status);
        Assert.Equal(1, gateway.RefundCalls);
    }

    [Fact]
    public async Task Reschedule_cancels_existing_intent_before_replacing_payment_data()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var gateway = new FakePaymentGateway(
            intent: new GatewayPaymentIntent("pi_test", "secret", "requires_payment_method", 120000, 0, "bam"),
            cancelledIntent: new GatewayPaymentIntent("pi_test", "secret", "canceled", 120000, 0, "bam"));
        var reservation = await fixture.Context.Reservations.SingleAsync();
        var service = new ReservationService(fixture.Context, gateway);

        var result = await service.RescheduleAsync(
            reservation.Id,
            new RescheduleReservationRequest
            {
                CheckIn = new DateOnly(2027, 2, 10),
                CheckOut = new DateOnly(2027, 2, 12)
            },
            reservation.GuestId);

        Assert.NotNull(result);
        Assert.Equal(1, gateway.CancelCalls);
        var payment = await fixture.Context.Payments.SingleAsync();
        Assert.Null(payment.ProviderReference);
        Assert.Equal(PaymentStatus.Pending, payment.Status);
        Assert.Equal(600m, payment.Amount);
    }

    [Fact]
    public async Task Guest_cancellation_requires_a_meaningful_reason()
    {
        await using var fixture = await PaymentFixture.CreateAsync();
        var service = new PaymentService(fixture.Context, new FakePaymentGateway());
        var reservation = await fixture.Context.Reservations.SingleAsync();

        var exception = await Assert.ThrowsAsync<RequestValidationException>(() =>
            service.CancelReservationAsync(
                reservation.Id,
                reservation.GuestId,
                isAdmin: false,
                isOwner: false,
                reason: "  "));

        Assert.Contains("najmanje 3 znaka", exception.Message);
    }

    private sealed class FakePaymentGateway(
        GatewayWebhookEvent? webhook = null,
        GatewayPaymentIntent? intent = null,
        GatewayRefund? refund = null,
        GatewayPaymentIntent? cancelledIntent = null,
        GatewayRefund? retrievedRefund = null) : IPaymentGateway
    {
        public int RefundCalls { get; private set; }
        public int CancelCalls { get; private set; }
        public string PublishableKey => "pk_test_fake";
        public Task<GatewayPaymentIntent> CreateIntentAsync(long amountInMinorUnits, string currency, int reservationId, int paymentId, string idempotencyKey, CancellationToken cancellationToken = default) =>
            throw new NotSupportedException();
        public Task<GatewayPaymentIntent> GetIntentAsync(string providerReference, CancellationToken cancellationToken = default) =>
            Task.FromResult(intent ?? throw new NotSupportedException());
        public Task<GatewayPaymentIntent> CancelIntentAsync(string providerReference, CancellationToken cancellationToken = default)
        {
            CancelCalls++;
            return Task.FromResult(cancelledIntent ?? throw new NotSupportedException());
        }
        public Task<GatewayRefund> GetRefundAsync(string refundReference, CancellationToken cancellationToken = default) =>
            Task.FromResult(retrievedRefund ?? throw new NotSupportedException());
        public Task<GatewayRefund> RefundAsync(string paymentIntentId, long amountInMinorUnits, string idempotencyKey, CancellationToken cancellationToken = default)
        {
            RefundCalls++;
            return Task.FromResult(refund ?? throw new NotSupportedException());
        }
        public GatewayWebhookEvent ParseWebhook(string payload, string signature) =>
            webhook ?? throw new NotSupportedException();
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
