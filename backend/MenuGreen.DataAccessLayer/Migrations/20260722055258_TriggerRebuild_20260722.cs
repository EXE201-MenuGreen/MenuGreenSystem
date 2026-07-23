using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MenuGreen.DataAccessLayer.Migrations
{
    /// <inheritdoc />
    public partial class TriggerRebuild_20260722 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "CarbsG",
                table: "meal_plan_items",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CustomName",
                table: "meal_plan_items",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "FatG",
                table: "meal_plan_items",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IngredientSnapshotJson",
                table: "meal_plan_items",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ProteinG",
                table: "meal_plan_items",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "QuantityG",
                table: "meal_plan_items",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SourceType",
                table: "meal_plan_items",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CustomName",
                table: "meal_logs",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CarbsG",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "CustomName",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "FatG",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "IngredientSnapshotJson",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "ProteinG",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "QuantityG",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "SourceType",
                table: "meal_plan_items");

            migrationBuilder.DropColumn(
                name: "CustomName",
                table: "meal_logs");
        }
    }
}
