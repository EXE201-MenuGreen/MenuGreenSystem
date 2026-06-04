using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserAiProfileConfiguration : IEntityTypeConfiguration<UserAiProfile>
    {
        public void Configure(EntityTypeBuilder<UserAiProfile> builder)
        {
            builder.ToTable("user_ai_profile");
            builder.HasKey(x => x.UserId);
            builder.Property(x => x.Preferences).HasColumnType("jsonb");
            builder.Property(x => x.DislikedFoods).HasColumnType("jsonb");
            // Stored as JSON string value, e.g. "gym" (valid jsonb).
            builder.Property(x => x.EatingPattern).HasColumnType("jsonb");

            builder.Property(x => x.UpdatedAt)
                .HasColumnType("timestamp with time zone");
            builder.HasOne(x => x.User).WithOne().HasForeignKey<UserAiProfile>(x => x.UserId);
        }
    }
}
