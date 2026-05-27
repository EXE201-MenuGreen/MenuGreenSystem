using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class WaterLogConfiguration : IEntityTypeConfiguration<WaterLog>
    {
        public void Configure(EntityTypeBuilder<WaterLog> builder)
        {
            builder.ToTable("water_logs");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.AmountMl)
                .IsRequired();

            builder.Property(x => x.LoggedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId);
            builder.HasIndex(x => x.LoggedAt);
        }
    }
}
