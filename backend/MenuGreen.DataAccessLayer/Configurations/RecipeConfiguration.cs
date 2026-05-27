using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class RecipeConfiguration : IEntityTypeConfiguration<Recipe>
    {
        public void Configure(EntityTypeBuilder<Recipe> builder)
        {
            builder.ToTable("recipes");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Title).IsRequired().HasColumnType("text");
            builder.Property(x => x.Description).HasColumnType("text");
            builder.Property(x => x.Difficulty).HasColumnType("text");
            builder.Property(x => x.MealType).HasColumnType("text");
            builder.Property(x => x.Instructions).HasColumnType("json");
            builder.Property(x => x.ImageUrl).HasColumnType("text");
            builder.Property(x => x.VideoUrl).HasColumnType("text");
            builder.HasOne(x => x.Food).WithMany(x => x.Recipes).HasForeignKey(x => x.FoodId);
        }
    }
}
