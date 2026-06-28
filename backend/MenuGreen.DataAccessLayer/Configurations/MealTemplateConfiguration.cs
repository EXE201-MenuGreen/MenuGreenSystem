using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealTemplateConfiguration : IEntityTypeConfiguration<MealTemplate>
    {
        public void Configure(EntityTypeBuilder<MealTemplate> builder)
        {
            builder.ToTable("meal_templates");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Title).HasMaxLength(255).IsRequired();
            builder.Property(x => x.Description).HasMaxLength(1000);
            builder.Property(x => x.MealType).HasMaxLength(50);
            builder.Property(x => x.IsActive).HasDefaultValue(true);
            builder.Property(x => x.UsageCount).HasDefaultValue(0);
            builder.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId);
            builder.HasIndex(x => x.MealType);
        }
    }
}
