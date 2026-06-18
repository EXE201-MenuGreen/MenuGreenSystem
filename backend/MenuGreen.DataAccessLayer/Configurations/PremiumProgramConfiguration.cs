using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class PremiumProgramConfiguration : IEntityTypeConfiguration<PremiumProgram>
    {
        public void Configure(EntityTypeBuilder<PremiumProgram> builder)
        {
            builder.ToTable("premium_programs");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Title).IsRequired().HasMaxLength(255);
            builder.Property(x => x.Description).IsRequired().HasColumnType("text");
            builder.Property(x => x.GoalType).IsRequired().HasMaxLength(100);
            builder.Property(x => x.SampleMenu).HasColumnType("text");
        }
    }
}
