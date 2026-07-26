using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealPlanHeaderConfiguration : IEntityTypeConfiguration<MealPlanHeader>
    {
        public void Configure(EntityTypeBuilder<MealPlanHeader> builder)
        {
            builder.ToTable("meal_plan_headers");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.Title)
                .HasMaxLength(255);

            builder.Property(x => x.PlanType)
                .HasMaxLength(50);

            builder.Property(x => x.GeneratedBy)
                .HasMaxLength(50);

            builder.Property(x => x.Status)
                .HasMaxLength(20)
                .HasDefaultValue("Active");

            builder.Property(x => x.ApprovedAt)
                .HasColumnType("timestamp with time zone");

            builder.Property(x => x.IsActive)
                .HasDefaultValue(true);

            builder.Property(x => x.CreatedAt)
                .HasColumnType("timestamp with time zone");

            builder.Property(x => x.UpdatedAt)
                .HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId);
            builder.HasIndex(x => x.PlanType);
            builder.HasIndex(x => x.StartDate);
            builder.HasIndex(x => x.Status);
        }
    }
}
