using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserProgramMilestoneConfiguration : IEntityTypeConfiguration<UserProgramMilestone>
    {
        public void Configure(EntityTypeBuilder<UserProgramMilestone> builder)
        {
            builder.ToTable("user_program_milestones");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.WeightKg).HasPrecision(18, 2);
            builder.Property(x => x.BodyFatPercent).HasPrecision(18, 2);
            builder.Property(x => x.ChestCm).HasPrecision(18, 2);
            builder.Property(x => x.WaistCm).HasPrecision(18, 2);
            builder.Property(x => x.HipCm).HasPrecision(18, 2);
            builder.Property(x => x.BadgeName).HasMaxLength(100);

            builder.HasOne(x => x.UserPremiumProgram)
                .WithMany(u => u.UserProgramMilestones)
                .HasForeignKey(x => x.UserProgramId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => new { x.UserProgramId, x.WeekNumber }).IsUnique();
        }
    }
}
