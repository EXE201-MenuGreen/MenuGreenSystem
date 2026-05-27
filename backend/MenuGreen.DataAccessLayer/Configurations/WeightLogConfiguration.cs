using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class WeightLogConfiguration : IEntityTypeConfiguration<WeightLog>
    {
        public void Configure(EntityTypeBuilder<WeightLog> builder)
        {
            builder.ToTable("weight_logs");
            builder.HasKey(x => x.Id);
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        }
    }
}
