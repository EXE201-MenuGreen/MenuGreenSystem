using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class DeviceTokenConfiguration : IEntityTypeConfiguration<DeviceToken>
    {
        public void Configure(EntityTypeBuilder<DeviceToken> builder)
        {
            builder.ToTable("device_tokens");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Token).IsRequired().HasMaxLength(500);
            builder.Property(x => x.DeviceType).HasMaxLength(100);
            builder.Property(x => x.DeviceName).HasMaxLength(100);
            builder.Property(x => x.AppVersion).HasMaxLength(200);
            builder.Property(x => x.IsActive).HasDefaultValue(true);
            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasIndex(x => x.UserId);
            builder.HasIndex(x => x.Token).IsUnique();
            builder.HasIndex(x => new { x.UserId, x.IsActive });

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
