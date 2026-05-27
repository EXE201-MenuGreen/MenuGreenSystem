using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealLogConfiguration : IEntityTypeConfiguration<MealLog>
    {
        public void Configure(EntityTypeBuilder<MealLog> builder)
        {
            builder.ToTable("meal_logs");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.MealType).HasColumnType("text");
            builder.Property(x => x.SourceType).HasColumnType("text");
            builder.Property(x => x.Notes).HasColumnType("text");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
            builder.HasOne(x => x.Food).WithMany().HasForeignKey(x => x.FoodId);
            builder.HasOne(x => x.Recipe).WithMany().HasForeignKey(x => x.RecipeId);
        }
    }
}
