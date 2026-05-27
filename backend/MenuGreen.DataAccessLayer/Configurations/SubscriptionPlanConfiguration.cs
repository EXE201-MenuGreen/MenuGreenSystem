using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class SubscriptionPlanConfiguration : IEntityTypeConfiguration<SubscriptionPlan>
    {
        public void Configure(EntityTypeBuilder<SubscriptionPlan> builder)
        {
            builder.ToTable("subscription_plans");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Name).HasColumnType("text");
            builder.Property(x => x.Description).HasColumnType("text");
            builder.Property(x => x.FeatureGroup).HasColumnType("text");
        }
    }
}
