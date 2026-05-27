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
            builder.Property(x => x.Preferences).HasColumnType("json");
            builder.Property(x => x.DislikedFoods).HasColumnType("json");
            builder.Property(x => x.EatingPattern).HasColumnType("json");
            builder.HasOne(x => x.User).WithOne().HasForeignKey<UserAiProfile>(x => x.UserId);
        }
    }
}
