using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class CustomUserPortionConfiguration : IEntityTypeConfiguration<CustomUserPortion>
    {
        public void Configure(EntityTypeBuilder<CustomUserPortion> builder)
        {
            builder.ToTable("custom_user_portions");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.UnitName).IsRequired().HasMaxLength(150);
            builder.Property(x => x.GramsEquivalent).HasPrecision(18, 2);

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => new { x.UserId, x.UnitName }).IsUnique();
        }
    }
}
