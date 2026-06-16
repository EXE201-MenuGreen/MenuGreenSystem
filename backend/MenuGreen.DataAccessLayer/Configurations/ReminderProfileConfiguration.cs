using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class ReminderProfileConfiguration : IEntityTypeConfiguration<ReminderProfile>
    {
        public void Configure(EntityTypeBuilder<ReminderProfile> builder)
        {
            builder.ToTable("reminder_profiles");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.OptimalBreakfastTime).HasColumnType("time without time zone").IsRequired();
            builder.Property(x => x.OptimalLunchTime).HasColumnType("time without time zone").IsRequired();
            builder.Property(x => x.OptimalDinnerTime).HasColumnType("time without time zone").IsRequired();
            builder.Property(x => x.LastRecalculatedAt).HasColumnType("timestamp with time zone").IsRequired();

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId);
        }
    }
}
