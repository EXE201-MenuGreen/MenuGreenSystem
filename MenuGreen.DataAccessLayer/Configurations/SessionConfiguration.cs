using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class SessionConfiguration : IEntityTypeConfiguration<Session>
    {
        public void Configure(EntityTypeBuilder<Session> builder)
        {
            builder.ToTable("sessions");

            builder.HasKey(s => s.Id);

            builder.Property(s => s.RefreshToken)
                .IsRequired()
                .HasColumnType("text");

            builder.HasIndex(s => s.RefreshToken)
                .IsUnique();

            builder.Property(s => s.UserAgent)
                .HasColumnType("text");

            // Assuming PostgreSQL for inet
            builder.Property(s => s.IpAddress)
                .HasColumnType("inet");
        }
    }
}
