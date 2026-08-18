using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Notifications;
using CabinRent.Model.Payments;
using CabinRent.Services.Payments;
using Microsoft.EntityFrameworkCore;
using CabinRent.Model.Notifications;
using System.Data;

namespace CabinRent.Infrastructure.Payments;

public sealed class PaymentService(CabinRentDbContext dbContext, IPaymentGateway paymentGateway) : IPaymentService
{
    private static readonly HashSet<string> SupportedWebhookTypes = new(StringComparer.Ordinal)
    {
        "payment_intent.succeeded",
        "payment_intent.payment_failed",
        "payment_intent.processing"
    };

    public async Task<PaymentIntentDto> CreateIntentAsync(int reservationId, int guestId, CancellationToken cancellationToken = default)
    {
        var reservation = await dbContext.Reservations
            .Include(x => x.Payment)
            .SingleOrDefaultAsync(x => x.Id == reservationId, cancellationToken)
            ?? throw new KeyNotFoundException("Rezervacija nije pronađena.");

        if (reservation.GuestId != guestId)
            throw new UnauthorizedAccessException("Možete platiti samo vlastitu rezervaciju.");
        var payment = reservation.Payment;
        if (!PaymentRules.CanStartPayment(reservation.Status, payment?.Status, reservation.CheckOut, DateOnly.FromDateTime(DateTime.UtcNow)))
            throw new InvalidOperationException(payment?.Status switch
            {
                PaymentStatus.Paid => "Rezervacija je već plaćena.",
                PaymentStatus.Refunded => "Refundirana rezervacija se ne može ponovo platiti.",
                _ when reservation.CheckOut <= DateOnly.FromDateTime(DateTime.UtcNow) => "Nije moguće platiti rezervaciju čiji je termin prošao.",
                _ => "Moguće je platiti samo potvrđenu rezervaciju."
            });

        if (payment is null)
        {
            payment = new Payment
            {
                ReservationId = reservation.Id,
                Amount = reservation.TotalPrice,
                Currency = "BAM",
                Provider = "Stripe",
                Status = PaymentStatus.Pending
            };
            dbContext.Payments.Add(payment);
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        else
        {
            payment.Amount = reservation.TotalPrice;
            payment.Currency = "BAM";
            payment.Provider = "Stripe";
            payment.FailureMessage = null;
        }

        GatewayPaymentIntent intent;
        if (!string.IsNullOrWhiteSpace(payment.ProviderReference))
        {
            intent = await paymentGateway.GetIntentAsync(payment.ProviderReference, cancellationToken);
        }
        else
        {
            var minorUnits = PaymentRules.ToMinorUnits(payment.Amount);
            intent = await paymentGateway.CreateIntentAsync(
                minorUnits,
                payment.Currency,
                reservation.Id,
                payment.Id,
                $"reservation-{reservation.Id}-payment-{payment.Id}",
                cancellationToken);
            payment.ProviderReference = intent.Id;
            payment.UpdatedAtUtc = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return new PaymentIntentDto(
            payment.Id,
            reservation.Id,
            payment.Amount,
            payment.Currency,
            intent.Status,
            intent.ClientSecret,
            paymentGateway.PublishableKey);
    }

    public async Task<PaymentWebhookResultDto> ProcessWebhookAsync(
        string payload,
        string signature,
        CancellationToken cancellationToken = default)
    {
        var webhook = paymentGateway.ParseWebhook(payload, signature);
        await using var transaction = await dbContext.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);

        if (await dbContext.PaymentWebhookEvents.AnyAsync(x => x.ProviderEventId == webhook.EventId, cancellationToken))
            return new PaymentWebhookResultDto(webhook.EventId, "Duplicate");

        if (!SupportedWebhookTypes.Contains(webhook.Type) || string.IsNullOrWhiteSpace(webhook.PaymentIntentId))
            return await StoreWebhookResultAsync(webhook, "Ignored", "Događaj ne zahtijeva obradu.", transaction, cancellationToken);

        var payment = await dbContext.Payments
            .Include(x => x.Reservation).ThenInclude(x => x.Cabin)
            .SingleOrDefaultAsync(x => x.ProviderReference == webhook.PaymentIntentId, cancellationToken);

        if (payment is null)
            return await StoreWebhookResultAsync(webhook, "Ignored", "PaymentIntent nije povezan s lokalnim plaćanjem.", transaction, cancellationToken);

        var outcome = webhook.Type switch
        {
            "payment_intent.succeeded" => HandleSucceeded(payment, webhook),
            "payment_intent.payment_failed" => HandleFailed(payment, webhook),
            "payment_intent.processing" => "Pending",
            _ => "Ignored"
        };

        if (outcome is "Paid" or "Failed")
            AddPaymentNotifications(payment, outcome);

        dbContext.PaymentWebhookEvents.Add(CreateWebhookRecord(webhook, outcome, OutcomeDetails(outcome)));
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new PaymentWebhookResultDto(webhook.EventId, outcome);
    }

    private static string HandleSucceeded(Payment payment, GatewayWebhookEvent webhook)
    {
        if (payment.Status == PaymentStatus.Refunded) return "Ignored";
        if (payment.Status == PaymentStatus.Paid) return "AlreadyPaid";
        if (!webhook.AmountReceived.HasValue || string.IsNullOrWhiteSpace(webhook.Currency) ||
            !PaymentRules.MatchesExpectedPayment(payment.Amount, payment.Currency, webhook.AmountReceived.Value, webhook.Currency))
            return "RejectedAmountMismatch";

        payment.Status = PaymentStatus.Paid;
        payment.ChargedAmount = PaymentRules.FromMinorUnits(webhook.AmountReceived.Value);
        payment.PaidAtUtc = DateTime.UtcNow;
        payment.FailureMessage = null;
        payment.UpdatedAtUtc = DateTime.UtcNow;
        return "Paid";
    }

    private static string HandleFailed(Payment payment, GatewayWebhookEvent webhook)
    {
        if (payment.Status is PaymentStatus.Paid or PaymentStatus.Refunded) return "Ignored";
        payment.Status = PaymentStatus.Failed;
        payment.FailureMessage = string.IsNullOrWhiteSpace(webhook.FailureMessage)
            ? "Stripe nije odobrio plaćanje."
            : webhook.FailureMessage[..Math.Min(webhook.FailureMessage.Length, 1000)];
        payment.UpdatedAtUtc = DateTime.UtcNow;
        return "Failed";
    }

    private void AddPaymentNotifications(Payment payment, string outcome)
    {
        var paid = outcome == "Paid";
        var reservation = payment.Reservation;
        var occurredAtUtc = DateTime.UtcNow;
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.GuestId,
            paid ? "PaymentSucceeded" : "PaymentFailed",
            paid ? "Plaćanje uspješno" : "Plaćanje nije uspjelo",
            paid
                ? $"Rezervacija {reservation.ConfirmationCode} je uspješno plaćena."
                : $"Plaćanje rezervacije {reservation.ConfirmationCode} nije uspjelo. Možete pokušati ponovo.",
            "Reservation", reservation.Id, occurredAtUtc));
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.Cabin.OwnerId,
            paid ? "PaymentReceived" : "PaymentFailed",
            paid ? "Primljena uplata" : "Neuspjelo plaćanje rezervacije",
            paid
                ? $"Gost je platio rezervaciju {reservation.ConfirmationCode} za vikendicu {reservation.Cabin.Name}."
                : $"Plaćanje rezervacije {reservation.ConfirmationCode} za vikendicu {reservation.Cabin.Name} nije uspjelo.",
            "Reservation", reservation.Id, occurredAtUtc));
    }

    private async Task<PaymentWebhookResultDto> StoreWebhookResultAsync(
        GatewayWebhookEvent webhook,
        string outcome,
        string details,
        Microsoft.EntityFrameworkCore.Storage.IDbContextTransaction transaction,
        CancellationToken cancellationToken)
    {
        dbContext.PaymentWebhookEvents.Add(CreateWebhookRecord(webhook, outcome, details));
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new PaymentWebhookResultDto(webhook.EventId, outcome);
    }

    private static PaymentWebhookEvent CreateWebhookRecord(GatewayWebhookEvent webhook, string outcome, string? details) => new()
    {
        ProviderEventId = webhook.EventId,
        Type = webhook.Type,
        ProviderReference = webhook.PaymentIntentId,
        Outcome = outcome,
        Details = details,
        ProcessedAtUtc = DateTime.UtcNow
    };

    private static string? OutcomeDetails(string outcome) => outcome switch
    {
        "RejectedAmountMismatch" => "Stripe iznos ili valuta ne odgovaraju lokalnom plaćanju.",
        "Ignored" => "Status plaćanja nije promijenjen.",
        "AlreadyPaid" => "Plaćanje je već ranije označeno kao uspješno.",
        _ => null
    };
}
