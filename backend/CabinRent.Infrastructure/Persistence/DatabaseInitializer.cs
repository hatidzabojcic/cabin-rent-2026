using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CabinRent.Infrastructure.Persistence;

public static class DatabaseInitializer
{
    public static async Task InitializeDatabaseAsync(
        this IServiceProvider services,
        IConfiguration configuration,
        CancellationToken cancellationToken = default)
    {
        await using var scope = services.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<CabinRentDbContext>();

        await dbContext.Database.MigrateAsync(cancellationToken);
        await SeedReferenceDataAsync(dbContext, cancellationToken);
        await SeedUsersAsync(dbContext, configuration, cancellationToken);
        await SeedDemoDataAsync(dbContext, cancellationToken);
        await SeedSecondaryOwnerDataAsync(dbContext, configuration, cancellationToken);
    }

    private static async Task SeedReferenceDataAsync(CabinRentDbContext dbContext, CancellationToken cancellationToken)
    {
        if (!await dbContext.Roles.AnyAsync(cancellationToken))
        {
            dbContext.Roles.AddRange(
                new Role { Name = "Admin", Description = "Potpuni pristup sistemu" },
                new Role { Name = "Owner", Description = "Upravlja vlastitim vikendicama i rezervacijama" },
                new Role { Name = "Guest", Description = "Pretražuje i rezerviše vikendice" });
        }

        if (!await dbContext.Countries.AnyAsync(cancellationToken))
        {
            dbContext.Countries.AddRange(
                new Country
                {
                    Name = "Bosna i Hercegovina",
                    IsoCode = "BA",
                    Cities =
                    [
                        new City { Name = "Sarajevo", PostalCode = "71000" },
                        new City { Name = "Mostar", PostalCode = "88000" },
                        new City { Name = "Bihać", PostalCode = "77000" },
                        new City { Name = "Konjic", PostalCode = "88400" },
                        new City { Name = "Jajce", PostalCode = "70101" }
                    ]
                },
                new Country
                {
                    Name = "Hrvatska",
                    IsoCode = "HR",
                    Cities =
                    [
                        new City { Name = "Zagreb", PostalCode = "10000" },
                        new City { Name = "Split", PostalCode = "21000" }
                    ]
                });
        }

        if (!await dbContext.CabinTypes.AnyAsync(cancellationToken))
        {
            dbContext.CabinTypes.AddRange(
                new CabinType { Name = "Planinska vikendica", Description = "Vikendica u planinskom okruženju" },
                new CabinType { Name = "Brvnara", Description = "Tradicionalni drveni objekat" },
                new CabinType { Name = "Kuća uz jezero", Description = "Smještaj u neposrednoj blizini vode" },
                new CabinType { Name = "Eco lodge", Description = "Održivi smještaj u prirodi" });
        }

        if (!await dbContext.Amenities.AnyAsync(cancellationToken))
        {
            dbContext.Amenities.AddRange(
                new Amenity { Name = "Wi-Fi", Icon = "wifi" },
                new Amenity { Name = "Parking", Icon = "local_parking" },
                new Amenity { Name = "Klima uređaj", Icon = "ac_unit" },
                new Amenity { Name = "Kamin", Icon = "fireplace" },
                new Amenity { Name = "Bazen", Icon = "pool" },
                new Amenity { Name = "Sauna", Icon = "sauna" },
                new Amenity { Name = "Roštilj", Icon = "outdoor_grill" },
                new Amenity { Name = "Dozvoljeni ljubimci", Icon = "pets" });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SeedUsersAsync(
        CabinRentDbContext dbContext,
        IConfiguration configuration,
        CancellationToken cancellationToken)
    {
        var accounts = new[]
        {
            new SeedAccount("Admin", "Admin", "CabinRent", "admin@cabinrent.local", "AdminUserName", "AdminPassword"),
            new SeedAccount("Owner", "Demo", "Owner", "owner@cabinrent.local", "OwnerUserName", "OwnerPassword"),
            new SeedAccount("Owner", "Test", "Owner", "owner2@cabinrent.local", "Owner2UserName", "Owner2Password"),
            new SeedAccount("Guest", "Demo", "Guest", "guest@cabinrent.local", "GuestUserName", "GuestPassword")
        };

        foreach (var account in accounts)
        {
            var userName = configuration[$"Seed:{account.UserNameSetting}"];
            var password = configuration[$"Seed:{account.PasswordSetting}"];
            if (string.IsNullOrWhiteSpace(userName) || string.IsNullOrWhiteSpace(password))
                throw new InvalidOperationException($"Seed credentials are missing for role '{account.RoleName}'.");

            var normalizedUserName = userName.Trim().ToLowerInvariant();
            if (await dbContext.Users.AnyAsync(x => x.UserName == normalizedUserName, cancellationToken))
                continue;

            var role = await dbContext.Roles.SingleAsync(x => x.Name == account.RoleName, cancellationToken);
            dbContext.Users.Add(new User
            {
                FirstName = account.FirstName,
                LastName = account.LastName,
                Email = account.Email,
                UserName = normalizedUserName,
                PasswordHash = PasswordHash.Create(password),
                UserRoles = [new UserRole { Role = role }]
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SeedSecondaryOwnerDataAsync(
        CabinRentDbContext dbContext,
        IConfiguration configuration,
        CancellationToken cancellationToken)
    {
        const string cabinName = "Blidinje hideaway";
        if (await dbContext.Cabins.AnyAsync(x => x.Name == cabinName, cancellationToken)) return;

        var ownerUserName = configuration["Seed:Owner2UserName"]?.Trim().ToLowerInvariant()
            ?? throw new InvalidOperationException("Second owner seed username is missing.");
        var owner = await dbContext.Users.SingleAsync(x => x.UserName == ownerUserName, cancellationToken);
        var city = await dbContext.Cities.SingleAsync(x => x.Name == "Mostar", cancellationToken);
        var cabinType = await dbContext.CabinTypes.SingleAsync(x => x.Name == "Brvnara", cancellationToken);
        var amenityIds = await dbContext.Amenities
            .Where(x => x.Name == "Wi-Fi" || x.Name == "Parking" || x.Name == "Kamin")
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        var cabin = new Cabin
        {
            Name = cabinName,
            Description = "Mirna planinska brvnara u blizini Parka prirode Blidinje, pogodna za porodični odmor.",
            Address = "Blidinje bb",
            AreaSquareMeters = 82,
            PricePerNight = 165,
            MaxAdults = 4,
            MaxChildren = 2,
            Bedrooms = 2,
            Bathrooms = 1,
            Latitude = 43.604,
            Longitude = 17.493,
            Owner = owner,
            City = city,
            CabinType = cabinType,
            Images =
            [
                new CabinImage
                {
                    Url = "https://images.unsplash.com/photo-1520984032042-162d526883e0?auto=format&fit=crop&w=1200&q=80",
                    AltText = cabinName,
                    IsCover = true,
                    SortOrder = 1
                }
            ]
        };
        cabin.CabinAmenities = amenityIds
            .Select(id => new CabinAmenity { Cabin = cabin, AmenityId = id })
            .ToList();
        dbContext.Cabins.Add(cabin);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private static async Task SeedDemoDataAsync(CabinRentDbContext dbContext, CancellationToken cancellationToken)
    {
        if (await dbContext.Cabins.AnyAsync(cancellationToken))
            return;

        var owner = await dbContext.Users.SingleAsync(x => x.UserName == "owner", cancellationToken);
        var guest = await dbContext.Users.SingleAsync(x => x.UserName == "guest", cancellationToken);
        var cities = await dbContext.Cities.ToDictionaryAsync(x => x.Name, cancellationToken);
        var types = await dbContext.CabinTypes.ToDictionaryAsync(x => x.Name, cancellationToken);
        var amenities = await dbContext.Amenities.ToDictionaryAsync(x => x.Name, cancellationToken);

        Cabin CreateCabin(
            string name, string description, string address, string city, string type,
            decimal area, decimal price, int adults, int children, int bedrooms, int bathrooms,
            double latitude, double longitude, string imageUrl, params string[] amenityNames)
        {
            var cabin = new Cabin
            {
                Name = name,
                Description = description,
                Address = address,
                City = cities[city],
                CabinType = types[type],
                Owner = owner,
                AreaSquareMeters = area,
                PricePerNight = price,
                MaxAdults = adults,
                MaxChildren = children,
                Bedrooms = bedrooms,
                Bathrooms = bathrooms,
                Latitude = latitude,
                Longitude = longitude,
                Images =
                [
                    new CabinImage { Url = imageUrl, AltText = name, IsCover = true, SortOrder = 1 },
                    new CabinImage { Url = $"{imageUrl}&sat=-10", AltText = $"{name} - interijer", SortOrder = 2 }
                ]
            };
            cabin.CabinAmenities = amenityNames
                .Select(name => new CabinAmenity { Amenity = amenities[name], Cabin = cabin })
                .ToList();
            return cabin;
        }

        var cabins = new[]
        {
            CreateCabin(
                "Jahorinska idila", "Topla planinska vikendica uz skijaške staze, sa kaminom i saunom.",
                "Obućina Bare 12", "Sarajevo", "Planinska vikendica", 92, 180, 6, 2, 3, 2,
                43.735, 18.565, "https://images.unsplash.com/photo-1449158743715-0a90ebb6d2d8?auto=format&fit=crop&w=1200&q=80",
                "Wi-Fi", "Parking", "Kamin", "Sauna", "Roštilj"),
            CreateCabin(
                "Neretva retreat", "Mirna kuća uz rijeku, idealna za porodice i vikend odmor.",
                "Glavatičevo bb", "Konjic", "Kuća uz jezero", 110, 220, 6, 3, 3, 2,
                43.487, 18.102, "https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=1200&q=80",
                "Wi-Fi", "Parking", "Klima uređaj", "Roštilj", "Dozvoljeni ljubimci"),
            CreateCabin(
                "Una forest lodge", "Eco lodge okružen šumom u blizini Nacionalnog parka Una.",
                "Ripač 45", "Bihać", "Eco lodge", 78, 145, 4, 2, 2, 1,
                44.773, 15.946, "https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=1200&q=80",
                "Wi-Fi", "Parking", "Kamin", "Dozvoljeni ljubimci"),
            CreateCabin(
                "Plivsko gnijezdo", "Tradicionalna brvnara s pogledom na Plivsko jezero.",
                "Mile 8", "Jajce", "Brvnara", 64, 120, 4, 1, 2, 1,
                44.342, 17.270, "https://images.unsplash.com/photo-1520984032042-162d526883e0?auto=format&fit=crop&w=1200&q=80",
                "Wi-Fi", "Parking", "Kamin", "Roštilj")
        };

        dbContext.Cabins.AddRange(cabins);
        await dbContext.SaveChangesAsync(cancellationToken);

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var completed = new Reservation
        {
            Guest = guest, Cabin = cabins[0], CheckIn = today.AddDays(-30), CheckOut = today.AddDays(-27),
            Adults = 2, Children = 0, PricePerNight = cabins[0].PricePerNight, TotalPrice = cabins[0].PricePerNight * 3,
            Status = ReservationStatus.Completed, ConfirmationCode = "CR-DEMO-001",
            Payment = new Payment { Amount = cabins[0].PricePerNight * 3, Currency = "BAM", Provider = "Stripe-Test", ProviderReference = "pi_demo_001", Status = PaymentStatus.Paid, PaidAtUtc = DateTime.UtcNow.AddDays(-31) }
        };
        var confirmed = new Reservation
        {
            Guest = guest, Cabin = cabins[1], CheckIn = today.AddDays(14), CheckOut = today.AddDays(18),
            Adults = 2, Children = 2, PricePerNight = cabins[1].PricePerNight, TotalPrice = cabins[1].PricePerNight * 4,
            Status = ReservationStatus.Confirmed, ConfirmationCode = "CR-DEMO-002",
            Payment = new Payment { Amount = cabins[1].PricePerNight * 4, Currency = "BAM", Provider = "Stripe-Test", ProviderReference = "pi_demo_002", Status = PaymentStatus.Paid, PaidAtUtc = DateTime.UtcNow }
        };
        var pending = new Reservation
        {
            Guest = guest, Cabin = cabins[2], CheckIn = today.AddDays(35), CheckOut = today.AddDays(38),
            Adults = 2, Children = 1, PricePerNight = cabins[2].PricePerNight, TotalPrice = cabins[2].PricePerNight * 3,
            Status = ReservationStatus.Pending, ConfirmationCode = "CR-DEMO-003",
            Payment = new Payment { Amount = cabins[2].PricePerNight * 3, Currency = "BAM", Provider = "Stripe-Test", Status = PaymentStatus.Pending }
        };
        var cancelled = new Reservation
        {
            Guest = guest, Cabin = cabins[3], CheckIn = today.AddDays(7), CheckOut = today.AddDays(9),
            Adults = 2, Children = 0, PricePerNight = cabins[3].PricePerNight, TotalPrice = cabins[3].PricePerNight * 2,
            Status = ReservationStatus.Cancelled, ConfirmationCode = "CR-DEMO-004",
            Payment = new Payment { Amount = cabins[3].PricePerNight * 2, Currency = "BAM", Provider = "Stripe-Test", ProviderReference = "pi_demo_004", Status = PaymentStatus.Refunded }
        };

        dbContext.Reservations.AddRange(completed, confirmed, pending, cancelled);
        dbContext.Reviews.Add(new Review
        {
            Reservation = completed, Cabin = cabins[0], Guest = guest, Rating = 5,
            Comment = "Odlična lokacija, čisto i veoma ugodno. Rado ćemo ponovo doći.", IsApproved = true
        });
        dbContext.Favorites.AddRange(
            new Favorite { User = guest, Cabin = cabins[0] },
            new Favorite { User = guest, Cabin = cabins[2] });
        dbContext.AvailabilityBlocks.AddRange(
            new AvailabilityBlock { Cabin = cabins[0], From = today.AddDays(50), To = today.AddDays(54), Reason = "Redovno održavanje" },
            new AvailabilityBlock { Cabin = cabins[3], From = today.AddDays(25), To = today.AddDays(27), Reason = "Privatni termin vlasnika" });

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private sealed record SeedAccount(
        string RoleName,
        string FirstName,
        string LastName,
        string Email,
        string UserNameSetting,
        string PasswordSetting);
}
