using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserAllergyConfiguration : IEntityTypeConfiguration<UserAllergy>
    {
        public void Configure(EntityTypeBuilder<UserAllergy> builder)
        {
            builder.ToTable("user_allergies");
            builder.HasKey(x => new { x.UserId, x.AllergyId });
            builder.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
            builder.HasOne(x => x.Allergy).WithMany().HasForeignKey(x => x.AllergyId);
        }
    }
}
