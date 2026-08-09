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
            builder.Property(x => x.Headline).HasMaxLength(120);
            builder.Property(x => x.Bio).HasColumnType("text");
            builder.Property(x => x.CertificateUrl).HasMaxLength(500);
            builder.Property(x => x.PhoneNumber).HasMaxLength(30);
            builder.Property(x => x.City).HasMaxLength(120);
            builder.Property(x => x.LanguagesJson).HasColumnType("text");
            builder.Property(x => x.CoachingStylesJson).HasColumnType("text");
            builder.Property(x => x.ClientLevelsJson).HasColumnType("text");
            builder.Property(x => x.CertificatesJson).HasColumnType("text");
            builder.Property(x => x.GalleryUrlsJson).HasColumnType("text");
            builder.Property(x => x.Achievements).HasColumnType("text");
            builder.Property(x => x.IdentityDocumentUrl).HasMaxLength(1000);
            builder.Property(x => x.ApplicationStatus).IsRequired().HasMaxLength(30);
            builder.Property(x => x.ReviewNote).HasMaxLength(1000);

            builder.HasOne(x => x.User)
                .WithOne()
                .HasForeignKey<CoachProfile>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.UserId).IsUnique();
        }
    }
}
