using CabinRent.Infrastructure.Persistence;
using CabinRent.Infrastructure.Notifications;
using CabinRent.Model.Payments;
using CabinRent.Services.Payments;
using Microsoft.EntityFrameworkCore;
using CabinRent.Model.Notifications;
using System.Data;
using CabinRent.Infrastructure.Platform;

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
            ?? throw new ResourceNotFoundException("Rezervacija nije pronađena.");

        if (reservation.GuestId != guestId)
            throw new ForbiddenOperationException("Možete platiti samo vlastitu rezervaciju.");
        var payment = reservation.Payment;
        if (!PaymentRules.CanStartPayment(reservation.Status, payment?.Status, reservation.CheckOut, DateOnly.FromDateTime(DateTime.UtcNow)))
            throw new BusinessRuleException(payment?.Status switch
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

    public async Task<PaymentConfirmationDto> ConfirmIntentAsync(
        int reservationId,
        int guestId,
        CancellationToken cancellationToken = default)
    {
        var paymentReference = await dbContext.Payments.AsNoTracking()
            .Where(x => x.ReservationId == reservationId && x.Reservation.GuestId == guestId)
            .Select(x => x.ProviderReference)
            .SingleOrDefaultAsync(cancellationToken)
            ?? throw new ResourceNotFoundException("Plaćanje nije pronađeno.");

        if (string.IsNullOrWhiteSpace(paymentReference))
            throw new BusinessRuleException("Stripe PaymentIntent još nije kreiran.");

        var intent = await paymentGateway.GetIntentAsync(paymentReference, cancellationToken);
        await using var transaction = await dbContext.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        var payment = await dbContext.Payments
            .Include(x => x.Reservation).ThenInclude(x => x.Cabin)
            .SingleAsync(x => x.ReservationId == reservationId, cancellationToken);

        if (payment.Reservation.GuestId != guestId)
            throw new ForbiddenOperationException("Možete potvrditi samo vlastito plaćanje.");
        if (!string.Equals(payment.ProviderReference, intent.Id, StringComparison.Ordinal))
            throw new BusinessRuleException("Stripe PaymentIntent ne odgovara lokalnom plaćanju.");

        var outcome = ApplyIntentStatus(payment, intent);
        if (outcome is "Paid" or "Failed") AddPaymentNotifications(payment, outcome);

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return new PaymentConfirmationDto(
            payment.Id,
            reservationId,
            payment.Status.ToString(),
            payment.ChargedAmount ?? 0,
            payment.Currency);
    }

    public async Task<bool> CancelReservationAsync(
        int reservationId,
        int actorId,
        bool isAdmin,
        bool isOwner,
        CancellationToken cancellationToken = default)
    {
        var snapshot = await dbContext.Reservations.AsNoTracking()
            .Where(x => x.Id == reservationId)
            .Select(x => new
            {
                x.GuestId,
                OwnerId = x.Cabin.OwnerId,
                x.Status,
                PaymentStatus = x.Payment == null ? (PaymentStatus?)null : x.Payment.Status,
                ProviderReference = x.Payment == null ? null : x.Payment.ProviderReference,
                ChargedAmount = x.Payment == null ? null : x.Payment.ChargedAmount,
                PaymentAmount = x.Payment == null ? 0 : x.Payment.Amount
            })
            .SingleOrDefaultAsync(cancellationToken);
        if (snapshot is null) return false;

        var canManage = isAdmin || (isOwner && snapshot.OwnerId == actorId) || snapshot.GuestId == actorId;
        if (!canManage) throw new ForbiddenOperationException("Nemate pristup ovoj rezervaciji.");
        if (snapshot.Status == ReservationStatus.Cancelled && snapshot.PaymentStatus is not PaymentStatus.Paid)
            return true;
        if (snapshot.Status is ReservationStatus.Completed or ReservationStatus.Rejected)
            throw new BusinessRuleException("Završenu ili odbijenu rezervaciju nije moguće otkazati.");
        if (!isAdmin && !isOwner && !ReservationStatusRules.CanGuestCancel(
                snapshot.Status,
                await dbContext.Reservations.Where(x => x.Id == reservationId).Select(x => x.CheckIn).SingleAsync(cancellationToken),
                DateOnly.FromDateTime(DateTime.UtcNow)))
            throw new BusinessRuleException("Rezervaciju je moguće otkazati samo prije dana dolaska dok je na čekanju ili potvrđena.");

        GatewayRefund? refund = null;
        if (snapshot.PaymentStatus == PaymentStatus.Paid)
        {
            if (string.IsNullOrWhiteSpace(snapshot.ProviderReference))
                throw new BusinessRuleException("Plaćanje nema Stripe referencu i ne može biti automatski refundirano.");
            var chargedAmount = snapshot.ChargedAmount ?? snapshot.PaymentAmount;
            refund = await paymentGateway.RefundAsync(
                snapshot.ProviderReference,
                PaymentRules.ToMinorUnits(chargedAmount),
                $"reservation-{reservationId}-full-refund",
                cancellationToken);
            if (!string.Equals(refund.Status, "succeeded", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(refund.Status, "pending", StringComparison.OrdinalIgnoreCase))
                throw new PaymentProviderException("Stripe nije potvrdio povrat novca. Rezervacija nije otkazana.");
            if (refund.Amount != PaymentRules.ToMinorUnits(chargedAmount) ||
                !string.Equals(refund.Currency, "bam", StringComparison.OrdinalIgnoreCase))
                throw new PaymentProviderException("Stripe refund iznos ili valuta ne odgovaraju lokalnom plaćanju. Rezervacija nije otkazana.");
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        var reservation = await dbContext.Reservations
            .Include(x => x.Cabin)
            .Include(x => x.Payment)
            .SingleAsync(x => x.Id == reservationId, cancellationToken);

        if (reservation.Status == ReservationStatus.Cancelled && reservation.Payment?.Status is not PaymentStatus.Paid)
            return true;
        reservation.Status = ReservationStatus.Cancelled;
        reservation.UpdatedAtUtc = DateTime.UtcNow;
        reservation.StatusChangedByUserId = actorId;
        reservation.StatusChangedAtUtc = DateTime.UtcNow;
        reservation.StatusChangeReason = refund is null
            ? "Rezervacija je otkazana."
            : "Rezervacija je otkazana i izvršen je povrat sredstava.";
        if (refund is not null && reservation.Payment is not null)
        {
            reservation.Payment.Status = PaymentStatus.Refunded;
            reservation.Payment.RefundReference = refund.Id;
            reservation.Payment.RefundedAmount = PaymentRules.FromMinorUnits(refund.Amount);
            reservation.Payment.RefundedAtUtc = DateTime.UtcNow;
            reservation.Payment.UpdatedAtUtc = DateTime.UtcNow;
        }

        AddCancellationNotifications(reservation, refund is not null);
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return true;
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

    private static string ApplyIntentStatus(Payment payment, GatewayPaymentIntent intent)
    {
        if (payment.Status == PaymentStatus.Refunded) return "Ignored";
        if (string.Equals(intent.Status, "succeeded", StringComparison.OrdinalIgnoreCase))
        {
            if (payment.Status == PaymentStatus.Paid) return "AlreadyPaid";
            if (!PaymentRules.MatchesExpectedPayment(payment.Amount, payment.Currency, intent.AmountReceived, intent.Currency))
                throw new BusinessRuleException("Stripe iznos ili valuta ne odgovaraju lokalnom plaćanju.");
            payment.Status = PaymentStatus.Paid;
            payment.ChargedAmount = PaymentRules.FromMinorUnits(intent.AmountReceived);
            payment.PaidAtUtc = DateTime.UtcNow;
            payment.FailureMessage = null;
            payment.UpdatedAtUtc = DateTime.UtcNow;
            return "Paid";
        }

        if (string.Equals(intent.Status, "canceled", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(intent.Status, "requires_payment_method", StringComparison.OrdinalIgnoreCase))
        {
            if (payment.Status == PaymentStatus.Paid) return "AlreadyPaid";
            payment.Status = PaymentStatus.Failed;
            payment.FailureMessage = "Stripe nije odobrio plaćanje.";
            payment.UpdatedAtUtc = DateTime.UtcNow;
            return "Failed";
        }

        return "Pending";
    }

    private void AddCancellationNotifications(Reservation reservation, bool refunded)
    {
        var occurredAtUtc = DateTime.UtcNow;
        var refundText = refunded ? " Uplaćeni iznos je refundiran putem Stripea." : string.Empty;
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.GuestId, "ReservationCancelled", "Rezervacija otkazana",
            $"Rezervacija {reservation.ConfirmationCode} je otkazana.{refundText}",
            "Reservation", reservation.Id, occurredAtUtc));
        dbContext.EnqueueNotification(new NotificationEvent(
            Guid.NewGuid(), reservation.Cabin.OwnerId, "ReservationCancelled", "Rezervacija otkazana",
            $"Rezervacija {reservation.ConfirmationCode} za vikendicu {reservation.Cabin.Name} je otkazana.{refundText}",
            "Reservation", reservation.Id, occurredAtUtc));
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
