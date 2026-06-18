using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class CoachConnectionConfiguration : IEntityTypeConfiguration<CoachConnection>
    {
        public void Configure(EntityTypeBuilder<CoachConnection> builder)
        {
            builder.ToTable("coach_connections");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Status).IsRequired().HasMaxLength(50);

            builder.HasOne(x => x.Client)
                .WithMany()
                .HasForeignKey(x => x.ClientId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.Coach)
                .WithMany()
                .HasForeignKey(x => x.CoachId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(x => new { x.ClientId, x.CoachId }).IsUnique();
        }
    }
}
