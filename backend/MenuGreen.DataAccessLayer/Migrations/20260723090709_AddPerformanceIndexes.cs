using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MenuGreen.DataAccessLayer.Migrations
{
    /// <inheritdoc />
    public partial class AddPerformanceIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_recipes_CreatedAt",
                table: "recipes",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_recipes_Difficulty",
                table: "recipes",
                column: "Difficulty");

            migrationBuilder.CreateIndex(
                name: "IX_recipes_IsActive",
                table: "recipes",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_recipes_MealType",
                table: "recipes",
                column: "MealType");

            migrationBuilder.CreateIndex(
                name: "IX_meal_logs_LoggedAt",
                table: "meal_logs",
                column: "LoggedAt");

            migrationBuilder.CreateIndex(
                name: "IX_meal_logs_UserId_LoggedAt",
                table: "meal_logs",
                columns: new[] { "UserId", "LoggedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ingredients_Category",
                table: "ingredients",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_ingredients_IsActive",
                table: "ingredients",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_ingredients_NameVi",
                table: "ingredients",
                column: "NameVi");

            migrationBuilder.CreateIndex(
                name: "IX_foods_Category",
                table: "foods",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_foods_IsActive",
                table: "foods",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_foods_NameVi",
                table: "foods",
                column: "NameVi");

            migrationBuilder.CreateIndex(
                name: "IX_foods_Region",
                table: "foods",
                column: "Region");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_recipes_CreatedAt",
                table: "recipes");

            migrationBuilder.DropIndex(
                name: "IX_recipes_Difficulty",
                table: "recipes");

            migrationBuilder.DropIndex(
                name: "IX_recipes_IsActive",
                table: "recipes");

            migrationBuilder.DropIndex(
                name: "IX_recipes_MealType",
                table: "recipes");

            migrationBuilder.DropIndex(
                name: "IX_meal_logs_LoggedAt",
                table: "meal_logs");

            migrationBuilder.DropIndex(
                name: "IX_meal_logs_UserId_LoggedAt",
                table: "meal_logs");

            migrationBuilder.DropIndex(
                name: "IX_ingredients_Category",
                table: "ingredients");

            migrationBuilder.DropIndex(
                name: "IX_ingredients_IsActive",
                table: "ingredients");

            migrationBuilder.DropIndex(
                name: "IX_ingredients_NameVi",
                table: "ingredients");

            migrationBuilder.DropIndex(
                name: "IX_foods_Category",
                table: "foods");

            migrationBuilder.DropIndex(
                name: "IX_foods_IsActive",
                table: "foods");

            migrationBuilder.DropIndex(
                name: "IX_foods_NameVi",
                table: "foods");

            migrationBuilder.DropIndex(
                name: "IX_foods_Region",
                table: "foods");
        }
    }
}
