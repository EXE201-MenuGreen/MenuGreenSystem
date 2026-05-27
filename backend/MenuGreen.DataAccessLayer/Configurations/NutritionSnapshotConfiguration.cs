using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class NutritionSnapshotConfiguration : IEntityTypeConfiguration<NutritionSnapshot>
    {
        public void Configure(EntityTypeBuilder<NutritionSnapshot> builder)
        {
            builder.ToTable("nutrition_snapshots");
            builder.HasKey(x => x.Id);
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        }
    }
}
