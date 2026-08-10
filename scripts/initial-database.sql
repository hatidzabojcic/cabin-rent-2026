IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Amenities] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(450) NOT NULL,
        [Icon] nvarchar(max) NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Amenities] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [CabinTypes] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(450) NOT NULL,
        [Description] nvarchar(max) NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_CabinTypes] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Countries] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [IsoCode] nvarchar(450) NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Countries] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Roles] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(450) NOT NULL,
        [Description] nvarchar(max) NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Roles] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Users] (
        [Id] int NOT NULL IDENTITY,
        [FirstName] nvarchar(max) NOT NULL,
        [LastName] nvarchar(max) NOT NULL,
        [Email] nvarchar(450) NOT NULL,
        [UserName] nvarchar(450) NOT NULL,
        [PasswordHash] nvarchar(max) NOT NULL,
        [PhoneNumber] nvarchar(max) NULL,
        [ProfileImageUrl] nvarchar(max) NULL,
        [IsActive] bit NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Cities] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [PostalCode] nvarchar(max) NULL,
        [CountryId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Cities] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cities_Countries_CountryId] FOREIGN KEY ([CountryId]) REFERENCES [Countries] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [UserRole] (
        [UserId] int NOT NULL,
        [RoleId] int NOT NULL,
        CONSTRAINT [PK_UserRole] PRIMARY KEY ([UserId], [RoleId]),
        CONSTRAINT [FK_UserRole_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [Roles] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_UserRole_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Cabins] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [Description] nvarchar(max) NOT NULL,
        [Address] nvarchar(max) NOT NULL,
        [AreaSquareMeters] decimal(8,2) NOT NULL,
        [PricePerNight] decimal(10,2) NOT NULL,
        [MaxAdults] int NOT NULL,
        [MaxChildren] int NOT NULL,
        [Bedrooms] int NOT NULL,
        [Bathrooms] int NOT NULL,
        [Latitude] float NULL,
        [Longitude] float NULL,
        [IsActive] bit NOT NULL,
        [OwnerId] int NOT NULL,
        [CityId] int NOT NULL,
        [CabinTypeId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Cabins] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Cabins_CabinTypes_CabinTypeId] FOREIGN KEY ([CabinTypeId]) REFERENCES [CabinTypes] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Cabins_Cities_CityId] FOREIGN KEY ([CityId]) REFERENCES [Cities] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Cabins_Users_OwnerId] FOREIGN KEY ([OwnerId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [AvailabilityBlocks] (
        [Id] int NOT NULL IDENTITY,
        [From] date NOT NULL,
        [To] date NOT NULL,
        [Reason] nvarchar(max) NULL,
        [CabinId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_AvailabilityBlocks] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_AvailabilityBlock_Dates] CHECK ([To] > [From]),
        CONSTRAINT [FK_AvailabilityBlocks_Cabins_CabinId] FOREIGN KEY ([CabinId]) REFERENCES [Cabins] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [CabinAmenity] (
        [CabinId] int NOT NULL,
        [AmenityId] int NOT NULL,
        CONSTRAINT [PK_CabinAmenity] PRIMARY KEY ([CabinId], [AmenityId]),
        CONSTRAINT [FK_CabinAmenity_Amenities_AmenityId] FOREIGN KEY ([AmenityId]) REFERENCES [Amenities] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_CabinAmenity_Cabins_CabinId] FOREIGN KEY ([CabinId]) REFERENCES [Cabins] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [CabinImages] (
        [Id] int NOT NULL IDENTITY,
        [Url] nvarchar(max) NOT NULL,
        [AltText] nvarchar(max) NULL,
        [SortOrder] int NOT NULL,
        [IsCover] bit NOT NULL,
        [CabinId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_CabinImages] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CabinImages_Cabins_CabinId] FOREIGN KEY ([CabinId]) REFERENCES [Cabins] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Favorites] (
        [UserId] int NOT NULL,
        [CabinId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        CONSTRAINT [PK_Favorites] PRIMARY KEY ([UserId], [CabinId]),
        CONSTRAINT [FK_Favorites_Cabins_CabinId] FOREIGN KEY ([CabinId]) REFERENCES [Cabins] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Favorites_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Reservations] (
        [Id] int NOT NULL IDENTITY,
        [CheckIn] date NOT NULL,
        [CheckOut] date NOT NULL,
        [Adults] int NOT NULL,
        [Children] int NOT NULL,
        [PricePerNight] decimal(10,2) NOT NULL,
        [TotalPrice] decimal(12,2) NOT NULL,
        [Status] int NOT NULL,
        [SpecialRequests] nvarchar(max) NULL,
        [ConfirmationCode] nvarchar(450) NOT NULL,
        [GuestId] int NOT NULL,
        [CabinId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Reservations] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Reservation_Dates] CHECK ([CheckOut] > [CheckIn]),
        CONSTRAINT [CK_Reservation_Guests] CHECK ([Adults] > 0 AND [Children] >= 0),
        CONSTRAINT [CK_Reservation_Prices] CHECK ([PricePerNight] >= 0 AND [TotalPrice] >= 0),
        CONSTRAINT [FK_Reservations_Cabins_CabinId] FOREIGN KEY ([CabinId]) REFERENCES [Cabins] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Reservations_Users_GuestId] FOREIGN KEY ([GuestId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Payments] (
        [Id] int NOT NULL IDENTITY,
        [Amount] decimal(12,2) NOT NULL,
        [Currency] nvarchar(max) NOT NULL,
        [Provider] nvarchar(max) NOT NULL,
        [ProviderReference] nvarchar(max) NULL,
        [Status] int NOT NULL,
        [PaidAtUtc] datetime2 NULL,
        [ReservationId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Payments] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Payments_Reservations_ReservationId] FOREIGN KEY ([ReservationId]) REFERENCES [Reservations] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE TABLE [Reviews] (
        [Id] int NOT NULL IDENTITY,
        [Rating] int NOT NULL,
        [Comment] nvarchar(max) NULL,
        [IsApproved] bit NOT NULL,
        [ReservationId] int NOT NULL,
        [CabinId] int NOT NULL,
        [GuestId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_Reviews] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Review_Rating] CHECK ([Rating] BETWEEN 1 AND 5),
        CONSTRAINT [FK_Reviews_Cabins_CabinId] FOREIGN KEY ([CabinId]) REFERENCES [Cabins] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Reviews_Reservations_ReservationId] FOREIGN KEY ([ReservationId]) REFERENCES [Reservations] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Reviews_Users_GuestId] FOREIGN KEY ([GuestId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Amenities_Name] ON [Amenities] ([Name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_AvailabilityBlocks_CabinId] ON [AvailabilityBlocks] ([CabinId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_CabinAmenity_AmenityId] ON [CabinAmenity] ([AmenityId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_CabinImages_CabinId] ON [CabinImages] ([CabinId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Cabins_CabinTypeId] ON [Cabins] ([CabinTypeId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Cabins_CityId] ON [Cabins] ([CityId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Cabins_OwnerId] ON [Cabins] ([OwnerId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_CabinTypes_Name] ON [CabinTypes] ([Name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Cities_CountryId] ON [Cities] ([CountryId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Countries_IsoCode] ON [Countries] ([IsoCode]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Favorites_CabinId] ON [Favorites] ([CabinId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Payments_ReservationId] ON [Payments] ([ReservationId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Reservations_CabinId] ON [Reservations] ([CabinId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Reservations_ConfirmationCode] ON [Reservations] ([ConfirmationCode]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Reservations_GuestId] ON [Reservations] ([GuestId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Reviews_CabinId] ON [Reviews] ([CabinId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Reviews_GuestId] ON [Reviews] ([GuestId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Reviews_ReservationId] ON [Reviews] ([ReservationId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Roles_Name] ON [Roles] ([Name]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_UserRole_RoleId] ON [UserRole] ([RoleId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_UserName] ON [Users] ([UserName]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810185004_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810185004_InitialCreate', N'10.0.10');
END;

COMMIT;
GO
BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810194311_AddRefreshTokens'
)
BEGIN
    CREATE TABLE [RefreshTokens] (
        [Id] int NOT NULL IDENTITY,
        [TokenHash] nvarchar(450) NOT NULL,
        [ExpiresAtUtc] datetime2 NOT NULL,
        [RevokedAtUtc] datetime2 NULL,
        [ReplacedByTokenHash] nvarchar(max) NULL,
        [CreatedByIp] nvarchar(max) NULL,
        [RevokedByIp] nvarchar(max) NULL,
        [UserId] int NOT NULL,
        [CreatedAtUtc] datetime2 NOT NULL,
        [UpdatedAtUtc] datetime2 NULL,
        CONSTRAINT [PK_RefreshTokens] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_RefreshTokens_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810194311_AddRefreshTokens'
)
BEGIN
    CREATE UNIQUE INDEX [IX_RefreshTokens_TokenHash] ON [RefreshTokens] ([TokenHash]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810194311_AddRefreshTokens'
)
BEGIN
    CREATE INDEX [IX_RefreshTokens_UserId_ExpiresAtUtc] ON [RefreshTokens] ([UserId], [ExpiresAtUtc]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20260810194311_AddRefreshTokens'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20260810194311_AddRefreshTokens', N'10.0.10');
END;

COMMIT;
GO

