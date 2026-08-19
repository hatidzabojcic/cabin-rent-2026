using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CabinRent.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationStatusAudit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "StatusChangeReason",
                table: "Reservations",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "StatusChangedAtUtc",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "StatusChangedByUserId",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_StatusChangedByUserId",
                table: "Reservations",
                column: "StatusChangedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_Users_StatusChangedByUserId",
                table: "Reservations",
                column: "StatusChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_Users_StatusChangedByUserId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_StatusChangedByUserId",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "StatusChangeReason",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "StatusChangedAtUtc",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "StatusChangedByUserId",
                table: "Reservations");
        }
    }
}
