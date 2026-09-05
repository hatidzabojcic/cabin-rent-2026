using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CabinRent.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStableRoleCodes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Code",
                table: "Roles",
                type: "nvarchar(450)",
                nullable: true);

            migrationBuilder.Sql("""
                UPDATE [Roles]
                SET [Code] = CASE [Id]
                    WHEN 1 THEN 'Admin'
                    WHEN 2 THEN 'Owner'
                    WHEN 3 THEN 'Guest'
                    ELSE CONCAT('Role_', [Id])
                END
                WHERE [Code] IS NULL;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "Code",
                table: "Roles",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Roles_Code",
                table: "Roles",
                column: "Code",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Roles_Code",
                table: "Roles");

            migrationBuilder.DropColumn(
                name: "Code",
                table: "Roles");
        }
    }
}
