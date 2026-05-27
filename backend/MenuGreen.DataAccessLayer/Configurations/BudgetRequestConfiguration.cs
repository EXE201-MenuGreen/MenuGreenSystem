using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class BudgetRequestConfiguration : IEntityTypeConfiguration<BudgetRequest>
    {
        public void Configure(EntityTypeBuilder<BudgetRequest> builder)
        {
            builder.ToTable("budget_requests");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Result).HasColumnType("json");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
        }
    }
}
