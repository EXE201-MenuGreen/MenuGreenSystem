using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class HealthProfileConfiguration : IEntityTypeConfiguration<HealthProfile>
    {
        public void Configure(EntityTypeBuilder<HealthProfile> builder)
        {
            builder.ToTable("health_profiles");

            builder.HasKey(x => x.UserId);

            builder.Property(x => x.HeightCm)
                .HasColumnType("numeric(5,2)");

            builder.Property(x => x.WeightKg)
                .HasColumnType("numeric(5,2)");

            builder.Property(x => x.BodyFatPercent)
                .HasColumnType("numeric(5,2)");

            builder.Property(x => x.ActivityLevel)
                .HasMaxLength(50);

            builder.Property(x => x.Goal)
                .HasMaxLength(50);

            builder.Property(x => x.Bmi)
                .HasColumnType("numeric(5,2)");

            builder.Property(x => x.CreatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.Property(x => x.UpdatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.HasOne(x => x.User)
                .WithOne(u => u.HealthProfile)
                .HasForeignKey<HealthProfile>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
