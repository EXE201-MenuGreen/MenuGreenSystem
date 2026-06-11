using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealTemplateItemConfiguration : IEntityTypeConfiguration<MealTemplateItem>
    {
        public void Configure(EntityTypeBuilder<MealTemplateItem> builder)
        {
            builder.ToTable("meal_template_items");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.QuantityG).HasPrecision(18, 2);
            builder.Property(x => x.Notes).HasMaxLength(1000);
            builder.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.MealTemplate)
                .WithMany(x => x.Items)
                .HasForeignKey(x => x.MealTemplateId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.MealTemplateId);
            builder.HasIndex(x => x.SortOrder);
        }
    }
}
