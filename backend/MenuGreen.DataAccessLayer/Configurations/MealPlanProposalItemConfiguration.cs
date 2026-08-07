using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealPlanProposalItemConfiguration : IEntityTypeConfiguration<MealPlanProposalItem>
    {
        public void Configure(EntityTypeBuilder<MealPlanProposalItem> builder)
        {
            builder.ToTable("meal_plan_proposal_items");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Action).IsRequired().HasMaxLength(20);
            builder.Property(x => x.MealType).IsRequired().HasMaxLength(30);
            builder.Property(x => x.QuantityG).HasPrecision(10, 2);
            builder.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.Proposal).WithMany(x => x.Items)
                .HasForeignKey(x => x.ProposalId).OnDelete(DeleteBehavior.Cascade);
            builder.HasOne(x => x.ExistingMealPlanItem).WithMany()
                .HasForeignKey(x => x.ExistingMealPlanItemId).OnDelete(DeleteBehavior.SetNull);
            builder.HasOne(x => x.Food).WithMany().HasForeignKey(x => x.FoodId)
                .OnDelete(DeleteBehavior.SetNull);
            builder.HasOne(x => x.Recipe).WithMany().HasForeignKey(x => x.RecipeId)
                .OnDelete(DeleteBehavior.SetNull);

            builder.HasIndex(x => x.ProposalId);
            builder.HasIndex(x => x.PlannedDate);
        }
    }
}
