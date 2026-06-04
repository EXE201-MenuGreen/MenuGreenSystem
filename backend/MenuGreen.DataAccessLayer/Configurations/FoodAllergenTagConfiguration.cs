using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class FoodAllergenTagConfiguration : IEntityTypeConfiguration<FoodAllergenTag>
    {
        public void Configure(EntityTypeBuilder<FoodAllergenTag> builder)
        {
            builder.ToTable("food_allergen_tags");
            builder.HasKey(x => new { x.FoodId, x.AllergenKey });
            builder.Property(x => x.AllergenKey).HasMaxLength(64).IsRequired();
            builder.HasOne(x => x.Food).WithMany().HasForeignKey(x => x.FoodId).OnDelete(DeleteBehavior.Cascade);
        }
    }
}
