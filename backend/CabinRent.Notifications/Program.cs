using CabinRent.Infrastructure.Persistence;
using CabinRent.Notifications;
using Microsoft.EntityFrameworkCore;

var builder = Host.CreateApplicationBuilder(args);
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' is missing.");
builder.Services.AddDbContext<CabinRentDbContext>(options => options.UseSqlServer(connectionString));
builder.Services.AddHostedService<NotificationWorker>();
await builder.Build().RunAsync();
