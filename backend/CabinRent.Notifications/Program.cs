var builder = Host.CreateApplicationBuilder(args);
// RabbitMQ consumer and email sender will be registered here in the notification phase.
await builder.Build().RunAsync();
