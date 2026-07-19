using MenuGreen.DataAccessLayer.Context;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MenuGreen.DataAccessLayer.Migrations
{
    [DbContext(typeof(ApplicationDbContext))]
    [Migration("20260717110000_AddPremiumProgramMeasurementsAndRewards")]
    public partial class AddPremiumProgramMeasurementsAndRewards : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BadgeName",
                table: "user_program_milestones",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ChestCm",
                table: "user_program_milestones",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "HipCm",
                table: "user_program_milestones",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RewardPoints",
                table: "user_program_milestones",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<decimal>(
                name: "WaistCm",
                table: "user_program_milestones",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "BadgeName", table: "user_program_milestones");
            migrationBuilder.DropColumn(name: "ChestCm", table: "user_program_milestones");
            migrationBuilder.DropColumn(name: "HipCm", table: "user_program_milestones");
            migrationBuilder.DropColumn(name: "RewardPoints", table: "user_program_milestones");
            migrationBuilder.DropColumn(name: "WaistCm", table: "user_program_milestones");
        }
    }
}
