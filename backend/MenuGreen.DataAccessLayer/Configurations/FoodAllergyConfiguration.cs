using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class FoodAllergyConfiguration : IEntityTypeConfiguration<FoodAllergy>
    {
        public void Configure(EntityTypeBuilder<FoodAllergy> builder)
        {
            builder.ToTable("food_allergies");
            builder.HasKey(x => new { x.FoodId, x.AllergyId });
            builder.HasOne(x => x.Food).WithMany().HasForeignKey(x => x.FoodId);
            builder.HasOne(x => x.Allergy).WithMany().HasForeignKey(x => x.AllergyId);
        }
    }
}
