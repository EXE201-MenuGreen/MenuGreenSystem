using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class NotificationSettingConfiguration : IEntityTypeConfiguration<NotificationSetting>
    {
        public void Configure(EntityTypeBuilder<NotificationSetting> builder)
        {
            builder.ToTable("NotificationSettings");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.MealReminderEnabled).HasDefaultValue(true);
            builder.Property(x => x.MealReminderOffsetMinutes).HasDefaultValue(30);
            builder.Property(x => x.PrepReminderEnabled).HasDefaultValue(true);
            builder.Property(x => x.PrepReminderOffsetMinutes).HasDefaultValue(20);
            builder.Property(x => x.InAppEnabled).HasDefaultValue(true);
            builder.Property(x => x.PushEnabled).HasDefaultValue(false);
            builder.Property(x => x.CreatedAt).IsRequired();
            builder.Property(x => x.UpdatedAt).IsRequired();

            builder.HasIndex(x => x.UserId).IsUnique();

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
