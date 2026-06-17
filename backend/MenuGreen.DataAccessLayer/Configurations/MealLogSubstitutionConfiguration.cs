using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealLogSubstitutionConfiguration : IEntityTypeConfiguration<MealLogSubstitution>
    {
        public void Configure(EntityTypeBuilder<MealLogSubstitution> builder)
        {
            builder.ToTable("meal_log_substitutions");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.OriginalQuantity).IsRequired();
            builder.Property(x => x.SubstituteQuantity).IsRequired();
            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasOne(x => x.MealLog)
                .WithMany()
                .HasForeignKey(x => x.MealLogId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.OriginalIngredient)
                .WithMany()
                .HasForeignKey(x => x.OriginalIngredientId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.SubstituteIngredient)
                .WithMany()
                .HasForeignKey(x => x.SubstituteIngredientId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
