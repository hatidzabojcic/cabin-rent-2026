using Microsoft.EntityFrameworkCore;

namespace CabinRent.Infrastructure.Persistence;

public sealed class CabinRentDbContext(DbContextOptions<CabinRentDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<Country> Countries => Set<Country>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<CabinType> CabinTypes => Set<CabinType>();
    public DbSet<Cabin> Cabins => Set<Cabin>();
    public DbSet<CabinImage> CabinImages => Set<CabinImage>();
    public DbSet<Amenity> Amenities => Set<Amenity>();
    public DbSet<Reservation> Reservations => Set<Reservation>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<PaymentWebhookEvent> PaymentWebhookEvents => Set<PaymentWebhookEvent>();
    public DbSet<NotificationOutbox> NotificationOutbox => Set<NotificationOutbox>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Favorite> Favorites => Set<Favorite>();
    public DbSet<AvailabilityBlock> AvailabilityBlocks => Set<AvailabilityBlock>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<UserRole>().HasKey(x => new { x.UserId, x.RoleId });
        modelBuilder.Entity<CabinAmenity>().HasKey(x => new { x.CabinId, x.AmenityId });
        modelBuilder.Entity<Favorite>().HasKey(x => new { x.UserId, x.CabinId });

        modelBuilder.Entity<User>().HasIndex(x => x.Email).IsUnique();
        modelBuilder.Entity<User>().HasIndex(x => x.UserName).IsUnique();
        modelBuilder.Entity<Role>().HasIndex(x => x.Name).IsUnique();
        modelBuilder.Entity<Country>().HasIndex(x => x.IsoCode).IsUnique();
        modelBuilder.Entity<CabinType>().HasIndex(x => x.Name).IsUnique();
        modelBuilder.Entity<Amenity>().HasIndex(x => x.Name).IsUnique();
        modelBuilder.Entity<Reservation>().HasIndex(x => x.ConfirmationCode).IsUnique();
        modelBuilder.Entity<Payment>().HasIndex(x => x.ReservationId).IsUnique();
        modelBuilder.Entity<Payment>().HasIndex(x => x.ProviderReference).IsUnique().HasFilter("[ProviderReference] IS NOT NULL");
        modelBuilder.Entity<PaymentWebhookEvent>().HasIndex(x => x.ProviderEventId).IsUnique();
        modelBuilder.Entity<NotificationOutbox>().HasIndex(x => x.EventId).IsUnique();
        modelBuilder.Entity<NotificationOutbox>().HasIndex(x => new { x.PublishedAtUtc, x.NextAttemptAtUtc, x.CreatedAtUtc });
        modelBuilder.Entity<Review>().HasIndex(x => x.ReservationId).IsUnique();
        modelBuilder.Entity<RefreshToken>().HasIndex(x => x.TokenHash).IsUnique();
        modelBuilder.Entity<RefreshToken>().HasIndex(x => new { x.UserId, x.ExpiresAtUtc });
        modelBuilder.Entity<Notification>().HasIndex(x => x.EventId).IsUnique();
        modelBuilder.Entity<Notification>().HasIndex(x => new { x.UserId, x.IsRead, x.CreatedAtUtc });

        modelBuilder.Entity<Cabin>().Property(x => x.PricePerNight).HasPrecision(10, 2);
        modelBuilder.Entity<Cabin>().Property(x => x.AreaSquareMeters).HasPrecision(8, 2);
        modelBuilder.Entity<Reservation>().Property(x => x.PricePerNight).HasPrecision(10, 2);
        modelBuilder.Entity<Reservation>().Property(x => x.TotalPrice).HasPrecision(12, 2);
        modelBuilder.Entity<Payment>().Property(x => x.Amount).HasPrecision(12, 2);
        modelBuilder.Entity<Payment>().Property(x => x.ChargedAmount).HasPrecision(12, 2);
        modelBuilder.Entity<Payment>().Property(x => x.RefundedAmount).HasPrecision(12, 2);

        modelBuilder.Entity<PaymentWebhookEvent>().Property(x => x.ProviderEventId).HasMaxLength(255);
        modelBuilder.Entity<PaymentWebhookEvent>().Property(x => x.Type).HasMaxLength(100);
        modelBuilder.Entity<PaymentWebhookEvent>().Property(x => x.ProviderReference).HasMaxLength(255);
        modelBuilder.Entity<PaymentWebhookEvent>().Property(x => x.Outcome).HasMaxLength(50);
        modelBuilder.Entity<PaymentWebhookEvent>().Property(x => x.Details).HasMaxLength(1000);
        modelBuilder.Entity<NotificationOutbox>().Property(x => x.Type).HasMaxLength(100);
        modelBuilder.Entity<NotificationOutbox>().Property(x => x.Title).HasMaxLength(200);
        modelBuilder.Entity<NotificationOutbox>().Property(x => x.Message).HasMaxLength(1000);
        modelBuilder.Entity<NotificationOutbox>().Property(x => x.RelatedEntityType).HasMaxLength(100);
        modelBuilder.Entity<NotificationOutbox>().Property(x => x.LastError).HasMaxLength(1000);

        modelBuilder.Entity<Reservation>().ToTable(t =>
        {
            t.HasCheckConstraint("CK_Reservation_Dates", "[CheckOut] > [CheckIn]");
            t.HasCheckConstraint("CK_Reservation_Guests", "[Adults] > 0 AND [Children] >= 0");
            t.HasCheckConstraint("CK_Reservation_Prices", "[PricePerNight] >= 0 AND [TotalPrice] >= 0");
        });
        modelBuilder.Entity<Review>().ToTable(t =>
            t.HasCheckConstraint("CK_Review_Rating", "[Rating] BETWEEN 1 AND 5"));
        modelBuilder.Entity<AvailabilityBlock>().ToTable(t =>
            t.HasCheckConstraint("CK_AvailabilityBlock_Dates", "[To] > [From]"));

        modelBuilder.Entity<Cabin>()
            .HasOne(x => x.Owner).WithMany(x => x.OwnedCabins)
            .HasForeignKey(x => x.OwnerId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Reservation>()
            .HasOne(x => x.Guest).WithMany()
            .HasForeignKey(x => x.GuestId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Reservation>()
            .HasOne(x => x.StatusChangedByUser).WithMany()
            .HasForeignKey(x => x.StatusChangedByUserId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Reservation>().Property(x => x.StatusChangeReason).HasMaxLength(500);
        modelBuilder.Entity<Review>()
            .HasOne(x => x.Guest).WithMany()
            .HasForeignKey(x => x.GuestId).OnDelete(DeleteBehavior.Restrict);
        modelBuilder.Entity<Review>()
            .HasOne(x => x.Cabin).WithMany()
            .HasForeignKey(x => x.CabinId).OnDelete(DeleteBehavior.Restrict);
    }
}
