using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class FoodPortionMappingConfiguration : IEntityTypeConfiguration<FoodPortionMapping>
    {
        public void Configure(EntityTypeBuilder<FoodPortionMapping> builder)
        {
            builder.ToTable("food_portion_mappings");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Unit).IsRequired().HasMaxLength(100);
            builder.Property(x => x.GramsPerUnit).HasPrecision(18, 2);

            builder.HasOne(x => x.Food)
                .WithMany()
                .HasForeignKey(x => x.FoodId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => new { x.FoodId, x.Unit }).IsUnique();
        }
    }
}
