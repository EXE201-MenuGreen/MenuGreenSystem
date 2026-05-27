using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class ActivityLogConfiguration : IEntityTypeConfiguration<ActivityLog>
    {
        public void Configure(EntityTypeBuilder<ActivityLog> builder)
        {
            builder.ToTable("activity_logs");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Action).HasColumnType("text");
            builder.Property(x => x.EntityType).HasColumnType("text");
            builder.Property(x => x.Metadata).HasColumnType("json");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        }
    }
}
