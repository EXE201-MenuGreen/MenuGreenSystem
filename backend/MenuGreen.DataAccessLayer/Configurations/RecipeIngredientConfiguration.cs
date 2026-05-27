using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class RecipeIngredientConfiguration : IEntityTypeConfiguration<RecipeIngredient>
    {
        public void Configure(EntityTypeBuilder<RecipeIngredient> builder)
        {
            builder.ToTable("recipe_ingredients");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Unit).HasColumnType("text");
            builder.Property(x => x.Notes).HasColumnType("text");
            builder.HasOne(x => x.Recipe).WithMany(x => x.RecipeIngredients).HasForeignKey(x => x.RecipeId);
            builder.HasOne(x => x.Ingredient).WithMany().HasForeignKey(x => x.IngredientId);
        }
    }
}
