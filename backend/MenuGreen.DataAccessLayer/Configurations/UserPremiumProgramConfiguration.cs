using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserPremiumProgramConfiguration : IEntityTypeConfiguration<UserPremiumProgram>
    {
        public void Configure(EntityTypeBuilder<UserPremiumProgram> builder)
        {
            builder.ToTable("user_premium_programs");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Status).IsRequired().HasMaxLength(50);

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.PremiumProgram)
                .WithMany(p => p.UserPremiumPrograms)
                .HasForeignKey(x => x.ProgramId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => new { x.UserId, x.ProgramId }).IsUnique();
        }
    }
}
