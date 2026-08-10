namespace CabinRent.Infrastructure.Persistence;

public abstract class Entity
{
    public int Id { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
}

public sealed class User : Entity
{
    public required string FirstName { get; set; }
    public required string LastName { get; set; }
    public required string Email { get; set; }
    public required string UserName { get; set; }
    public required string PasswordHash { get; set; }
    public string? PhoneNumber { get; set; }
    public string? ProfileImageUrl { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<UserRole> UserRoles { get; set; } = [];
    public ICollection<Cabin> OwnedCabins { get; set; } = [];
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
}

public sealed class Role : Entity
{
    public required string Name { get; set; }
    public string? Description { get; set; }
    public ICollection<UserRole> UserRoles { get; set; } = [];
}

public sealed class UserRole
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public int RoleId { get; set; }
    public Role Role { get; set; } = null!;
}

public sealed class Country : Entity
{
    public required string Name { get; set; }
    public required string IsoCode { get; set; }
    public ICollection<City> Cities { get; set; } = [];
}

public sealed class City : Entity
{
    public required string Name { get; set; }
    public string? PostalCode { get; set; }
    public int CountryId { get; set; }
    public Country Country { get; set; } = null!;
    public ICollection<Cabin> Cabins { get; set; } = [];
}

public sealed class CabinType : Entity
{
    public required string Name { get; set; }
    public string? Description { get; set; }
    public ICollection<Cabin> Cabins { get; set; } = [];
}

public sealed class Cabin : Entity
{
    public required string Name { get; set; }
    public required string Description { get; set; }
    public required string Address { get; set; }
    public decimal AreaSquareMeters { get; set; }
    public decimal PricePerNight { get; set; }
    public int MaxAdults { get; set; }
    public int MaxChildren { get; set; }
    public int Bedrooms { get; set; }
    public int Bathrooms { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsActive { get; set; } = true;
    public int OwnerId { get; set; }
    public User Owner { get; set; } = null!;
    public int CityId { get; set; }
    public City City { get; set; } = null!;
    public int CabinTypeId { get; set; }
    public CabinType CabinType { get; set; } = null!;
    public ICollection<CabinImage> Images { get; set; } = [];
    public ICollection<CabinAmenity> CabinAmenities { get; set; } = [];
    public ICollection<Reservation> Reservations { get; set; } = [];
}

public sealed class CabinImage : Entity
{
    public required string Url { get; set; }
    public string? AltText { get; set; }
    public int SortOrder { get; set; }
    public bool IsCover { get; set; }
    public int CabinId { get; set; }
    public Cabin Cabin { get; set; } = null!;
}

public sealed class Amenity : Entity
{
    public required string Name { get; set; }
    public string? Icon { get; set; }
    public ICollection<CabinAmenity> CabinAmenities { get; set; } = [];
}

public sealed class CabinAmenity
{
    public int CabinId { get; set; }
    public Cabin Cabin { get; set; } = null!;
    public int AmenityId { get; set; }
    public Amenity Amenity { get; set; } = null!;
}

public enum ReservationStatus { Pending, Confirmed, Cancelled, Completed, Rejected }
public enum PaymentStatus { Pending, Paid, Failed, Refunded }

public sealed class Reservation : Entity
{
    public DateOnly CheckIn { get; set; }
    public DateOnly CheckOut { get; set; }
    public int Adults { get; set; }
    public int Children { get; set; }
    public decimal PricePerNight { get; set; }
    public decimal TotalPrice { get; set; }
    public ReservationStatus Status { get; set; } = ReservationStatus.Pending;
    public string? SpecialRequests { get; set; }
    public string ConfirmationCode { get; set; } = Guid.NewGuid().ToString("N")[..10].ToUpperInvariant();
    public int GuestId { get; set; }
    public User Guest { get; set; } = null!;
    public int CabinId { get; set; }
    public Cabin Cabin { get; set; } = null!;
    public Payment? Payment { get; set; }
    public Review? Review { get; set; }
}

public sealed class Payment : Entity
{
    public decimal Amount { get; set; }
    public required string Currency { get; set; }
    public required string Provider { get; set; }
    public string? ProviderReference { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime? PaidAtUtc { get; set; }
    public int ReservationId { get; set; }
    public Reservation Reservation { get; set; } = null!;
}

public sealed class Review : Entity
{
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public bool IsApproved { get; set; }
    public int ReservationId { get; set; }
    public Reservation Reservation { get; set; } = null!;
    public int CabinId { get; set; }
    public Cabin Cabin { get; set; } = null!;
    public int GuestId { get; set; }
    public User Guest { get; set; } = null!;
}

public sealed class Favorite
{
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public int CabinId { get; set; }
    public Cabin Cabin { get; set; } = null!;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public sealed class AvailabilityBlock : Entity
{
    public DateOnly From { get; set; }
    public DateOnly To { get; set; }
    public string? Reason { get; set; }
    public int CabinId { get; set; }
    public Cabin Cabin { get; set; } = null!;
}

public sealed class RefreshToken : Entity
{
    public required string TokenHash { get; set; }
    public DateTime ExpiresAtUtc { get; set; }
    public DateTime? RevokedAtUtc { get; set; }
    public string? ReplacedByTokenHash { get; set; }
    public string? CreatedByIp { get; set; }
    public string? RevokedByIp { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
}
