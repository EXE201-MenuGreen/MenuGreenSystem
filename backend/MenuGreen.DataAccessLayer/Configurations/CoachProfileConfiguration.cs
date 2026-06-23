using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class CoachProfileConfiguration : IEntityTypeConfiguration<CoachProfile>
    {
        public void Configure(EntityTypeBuilder<CoachProfile> builder)
        {
            builder.ToTable("coach_profiles");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Specialty).IsRequired().HasMaxLength(255);
            builder.Property(x => x.Bio).HasColumnType("text");
            builder.Property(x => x.CertificateUrl).HasMaxLength(500);

            builder.HasOne(x => x.User)
                .WithOne()
                .HasForeignKey<CoachProfile>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId).IsUnique();
        }
    }
}
