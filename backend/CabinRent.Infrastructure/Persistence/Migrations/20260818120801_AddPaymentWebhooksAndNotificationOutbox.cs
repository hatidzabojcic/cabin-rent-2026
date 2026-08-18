using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CabinRent.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPaymentWebhooksAndNotificationOutbox : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "ProviderReference",
                table: "Payments",
                type: "nvarchar(450)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ChargedAmount",
                table: "Payments",
                type: "decimal(12,2)",
                precision: 12,
                scale: 2,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "NotificationOutbox",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EventId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RecipientUserId = table.Column<int>(type: "int", nullable: false),
                    Type = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    RelatedEntityType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    RelatedEntityId = table.Column<int>(type: "int", nullable: true),
                    OccurredAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    PublishedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    AttemptCount = table.Column<int>(type: "int", nullable: false),
                    NextAttemptAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LastError = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationOutbox", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "PaymentWebhookEvents",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ProviderEventId = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ProviderReference = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Outcome = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Details = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ProcessedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PaymentWebhookEvents", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ProviderReference",
                table: "Payments",
                column: "ProviderReference",
                unique: true,
                filter: "[ProviderReference] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationOutbox_EventId",
                table: "NotificationOutbox",
                column: "EventId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_NotificationOutbox_PublishedAtUtc_NextAttemptAtUtc_CreatedAtUtc",
                table: "NotificationOutbox",
                columns: new[] { "PublishedAtUtc", "NextAttemptAtUtc", "CreatedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_PaymentWebhookEvents_ProviderEventId",
                table: "PaymentWebhookEvents",
                column: "ProviderEventId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "NotificationOutbox");

            migrationBuilder.DropTable(
                name: "PaymentWebhookEvents");

            migrationBuilder.DropIndex(
                name: "IX_Payments_ProviderReference",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "ChargedAmount",
                table: "Payments");

            migrationBuilder.AlterColumn<string>(
                name: "ProviderReference",
                table: "Payments",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)",
                oldNullable: true);
        }
    }
}
