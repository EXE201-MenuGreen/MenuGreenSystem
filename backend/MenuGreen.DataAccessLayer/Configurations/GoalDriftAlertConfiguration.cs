using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class GoalDriftAlertConfiguration : IEntityTypeConfiguration<GoalDriftAlert>
    {
        public void Configure(EntityTypeBuilder<GoalDriftAlert> builder)
        {
            builder.ToTable("goal_drift_alerts");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.AlertType).HasMaxLength(50).IsRequired();
            builder.Property(x => x.Message).HasMaxLength(1000).IsRequired();
            builder.Property(x => x.AverageValue).HasPrecision(18, 2).IsRequired();
            builder.Property(x => x.TargetValue).HasPrecision(18, 2).IsRequired();
            builder.Property(x => x.PercentDeviation).HasPrecision(18, 2).IsRequired();
            builder.Property(x => x.IsAcknowledged).HasDefaultValue(false);
            builder.Property(x => x.IsDismissed).HasDefaultValue(false);
            builder.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").IsRequired();
            builder.Property(x => x.AcknowledgedAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.DismissedAt).HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId);
        }
    }
}
