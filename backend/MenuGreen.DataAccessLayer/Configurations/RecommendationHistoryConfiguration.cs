using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class RecommendationHistoryConfiguration : IEntityTypeConfiguration<RecommendationHistory>
    {
        public void Configure(EntityTypeBuilder<RecommendationHistory> builder)
        {
            builder.ToTable("recommendation_history");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Type).HasColumnType("text");
            builder.Property(x => x.Input).HasColumnType("json");
            builder.Property(x => x.Output).HasColumnType("json");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        }
    }
}
