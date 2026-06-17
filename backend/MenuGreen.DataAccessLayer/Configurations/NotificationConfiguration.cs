using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
    {
        public void Configure(EntityTypeBuilder<Notification> builder)
        {
            builder.ToTable("notifications");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Title).HasMaxLength(200);
            builder.Property(x => x.Body).HasMaxLength(1000);
            builder.Property(x => x.Type).HasMaxLength(100);
            builder.Property(x => x.IsRead).HasDefaultValue(false);
            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.Campaign)
                .WithMany()
                .HasForeignKey(x => x.CampaignId)
                .OnDelete(DeleteBehavior.SetNull);
        }
    }
}
