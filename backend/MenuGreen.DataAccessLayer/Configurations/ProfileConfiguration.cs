using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class ProfileConfiguration : IEntityTypeConfiguration<Profile>
    {
        public void Configure(EntityTypeBuilder<Profile> builder)
        {
            builder.ToTable("profiles");

            builder.HasKey(p => p.UserId);

            builder.Property(p => p.FullName)
                .HasMaxLength(255);

            builder.Property(p => p.AvatarUrl)
                .HasColumnType("text");

            builder.Property(p => p.Gender)
                .HasMaxLength(20);

            builder.Property(p => p.PreferredCuisine)
                .HasMaxLength(100);

            builder.Property(p => p.CreatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.Property(p => p.UpdatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.HasOne(p => p.User)
                .WithOne(u => u.Profile)
                .HasForeignKey<Profile>(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
