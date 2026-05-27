using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealPlanItemConfiguration : IEntityTypeConfiguration<MealPlanItem>
    {
        public void Configure(EntityTypeBuilder<MealPlanItem> builder)
        {
            builder.ToTable("meal_plan_items");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.MealType)
                .HasMaxLength(50);

            builder.Property(x => x.IsCompleted)
                .HasDefaultValue(false);

            builder.Property(x => x.CreatedAt)
                .HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.MealPlanHeader)
                .WithMany(h => h.MealPlanItems)
                .HasForeignKey(x => x.MealPlanId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.Food)
                .WithMany()
                .HasForeignKey(x => x.FoodId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasOne(x => x.Recipe)
                .WithMany()
                .HasForeignKey(x => x.RecipeId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(x => x.MealPlanId);
            builder.HasIndex(x => x.PlannedDate);
            builder.HasIndex(x => x.MealType);
        }
    }
}
