using CabinRent.Infrastructure.Auth;
using CabinRent.Infrastructure.Persistence;
using CabinRent.Model.Users;
using CabinRent.Services.Auth;
using CabinRent.Services.Cabins;
using CabinRent.Services.Exceptions;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Xunit;

namespace CabinRent.UnitTests.Auth;

public sealed class PasswordResetTests
{
    [Fact]
    public async Task Reset_changes_password_consumes_token_and_revokes_sessions()
    {
        await using var fixture = await ResetFixture.CreateAsync();
        await fixture.Service.RequestPasswordResetAsync(fixture.User.Email);

        await fixture.Service.ResetPasswordAsync(fixture.Delivery.Token!, "NovaLozinka123!");

        var user = await fixture.Context.Users.Include(x => x.RefreshTokens).SingleAsync();
        Assert.True(PasswordHash.Verify("NovaLozinka123!", user.PasswordHash));
        Assert.Equal(1, user.TokenVersion);
        Assert.All(user.RefreshTokens, token => Assert.NotNull(token.RevokedAtUtc));
        Assert.NotNull((await fixture.Context.PasswordResetTokens.SingleAsync()).UsedAtUtc);
        await Assert.ThrowsAsync<BusinessRuleException>(() =>
            fixture.Service.ResetPasswordAsync(fixture.Delivery.Token!, "JošJednaLozinka123!"));
    }

    [Fact]
    public async Task Expired_token_is_rejected()
    {
        await using var fixture = await ResetFixture.CreateAsync();
        await fixture.Service.RequestPasswordResetAsync(fixture.User.Email);
        var token = await fixture.Context.PasswordResetTokens.SingleAsync();
        token.ExpiresAtUtc = DateTime.UtcNow.AddMinutes(-1);
        await fixture.Context.SaveChangesAsync();

        await Assert.ThrowsAsync<BusinessRuleException>(() =>
            fixture.Service.ResetPasswordAsync(fixture.Delivery.Token!, "NovaLozinka123!"));
    }

    [Fact]
    public async Task Unknown_email_returns_normally_without_sending_token()
    {
        await using var fixture = await ResetFixture.CreateAsync();
        await fixture.Service.RequestPasswordResetAsync("unknown@test.local");
        Assert.Null(fixture.Delivery.Token);
        Assert.Empty(await fixture.Context.PasswordResetTokens.ToListAsync());
    }

    private sealed class ResetFixture : IAsyncDisposable
    {
        private readonly SqliteConnection connection;
        public CabinRentDbContext Context { get; }
        public User User { get; }
        public FakeDelivery Delivery { get; }
        public AuthService Service { get; }

        private ResetFixture(SqliteConnection connection, CabinRentDbContext context, User user)
        {
            this.connection = connection;
            Context = context;
            User = user;
            Delivery = new FakeDelivery();
            Service = new AuthService(context, Options.Create(new JwtOptions
            {
                Issuer = "test", Audience = "test",
                Key = "A-test-key-that-is-longer-than-thirty-two-characters"
            }), new FakeImageStorage(), Delivery);
        }

        public static async Task<ResetFixture> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();
            var context = new CabinRentDbContext(new DbContextOptionsBuilder<CabinRentDbContext>()
                .UseSqlite(connection).Options);
            await context.Database.EnsureCreatedAsync();
            var user = new User
            {
                FirstName = "Test", LastName = "Guest", Email = "guest@test.local",
                UserName = "guest", PasswordHash = PasswordHash.Create("StaraLozinka123!"),
                RefreshTokens = [new RefreshToken
                {
                    TokenHash = "refresh-hash", ExpiresAtUtc = DateTime.UtcNow.AddDays(1)
                }]
            };
            context.Users.Add(user);
            await context.SaveChangesAsync();
            return new ResetFixture(connection, context, user);
        }

        public async ValueTask DisposeAsync()
        {
            await Context.DisposeAsync();
            await connection.DisposeAsync();
        }
    }

    private sealed class FakeDelivery : IPasswordResetDelivery
    {
        public string? Token { get; private set; }
        public Task SendAsync(string email, string token, DateTime expiresAtUtc, CancellationToken cancellationToken = default)
        {
            Token = token;
            return Task.CompletedTask;
        }
    }

    private sealed class FakeImageStorage : IImageStorage
    {
        public Task<string> SaveAsync(int cabinId, Stream content, string extension, CancellationToken cancellationToken = default) =>
            Task.FromResult(string.Empty);
        public Task<string> SaveProfileAsync(int userId, Stream content, string extension, CancellationToken cancellationToken = default) =>
            Task.FromResult(string.Empty);
        public Task DeleteAsync(string url, CancellationToken cancellationToken = default) => Task.CompletedTask;
    }
}
