using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CabinRent.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AnonymizeDeletedGuestProfiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAtUtc",
                table: "Users",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeletedAtUtc",
                table: "Users");
        }
    }
}
