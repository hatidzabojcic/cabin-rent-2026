using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Payments;
using CabinRent.Services.Payments;
using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Payments;

public sealed class PaymentService(CabinRentDbContext dbContext, IPaymentGateway paymentGateway) : IPaymentService
{
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
}
