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

            builder.HasKey(p => p.Id);

            builder.Property(p => p.FullName)
                .HasColumnType("text");

            builder.Property(p => p.AvatarUrl)
                .HasColumnType("text");

            builder.Property(p => p.Role)
                .IsRequired()
                .HasColumnType("text");

            builder.Property(p => p.Gender)
                .HasColumnType("text");

            builder.Property(p => p.ActivityLevel)
                .IsRequired()
                .HasColumnType("text");

            builder.Property(p => p.Goal)
                .HasColumnType("text");

            builder.Property(p => p.PreferredCuisine)
                .HasColumnType("text");
        }
    }
}
