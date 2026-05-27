using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            builder.ToTable("users");

            builder.HasKey(u => u.Id);

            builder.Property(u => u.Email)
                .IsRequired()
                .HasColumnType("text");

            builder.HasIndex(u => u.Email)
                .IsUnique();

            builder.Property(u => u.PasswordHash)
                .IsRequired()
                .HasColumnType("text");

            builder.Property(u => u.EmailConfirmed)
                .HasDefaultValue(false);

            builder.Property(u => u.IsActive)
                .HasDefaultValue(true);

            builder.Property(u => u.LastSignInAt)
                .HasColumnType("timestamp with time zone");

            builder.Property(u => u.CreatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.Property(u => u.UpdatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.Property(u => u.DeletedAt)
                .HasColumnType("timestamp with time zone");

            // Relationships
            // 1-to-many: Role <-> Users
            builder.HasOne(u => u.Role)
                .WithMany(r => r.Users)
                .HasForeignKey(u => u.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            // 1-to-1: User <-> Profile
            builder.HasOne(u => u.Profile)
                .WithOne(p => p.User)
                .HasForeignKey<Profile>(p => p.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 1-to-1: User <-> HealthProfile
            builder.HasOne(u => u.HealthProfile)
                .WithOne(hp => hp.User)
                .HasForeignKey<HealthProfile>(hp => hp.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 1-to-many: User <-> Sessions
            builder.HasMany(u => u.Sessions)
                .WithOne(s => s.User)
                .HasForeignKey(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(u => u.RoleId);
        }
    }
}
