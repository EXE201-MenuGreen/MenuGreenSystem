using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MealPlanProposalConfiguration : IEntityTypeConfiguration<MealPlanProposal>
    {
        public void Configure(EntityTypeBuilder<MealPlanProposal> builder)
        {
            builder.ToTable("meal_plan_proposals");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.ProposalType).IsRequired().HasMaxLength(40);
            builder.Property(x => x.Status).IsRequired().HasMaxLength(20);
            builder.Property(x => x.ExpiresAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.SourcePlanVersion).HasColumnType("timestamp with time zone");
            builder.Property(x => x.ReminderSentAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.SubmittedAt).HasColumnType("timestamp with time zone");
            builder.Property(x => x.ActionedAt).HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            builder.HasOne(x => x.Coach).WithMany().HasForeignKey(x => x.CoachId)
                .OnDelete(DeleteBehavior.Restrict);
            builder.HasOne(x => x.ReviewRequest).WithMany()
                .HasForeignKey(x => x.ReviewRequestId).OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => new { x.ReviewRequestId, x.ProposalType }).IsUnique();
            builder.HasIndex(x => new { x.Status, x.ExpiresAt });
            builder.HasIndex(x => x.UserId);
            builder.HasIndex(x => x.CoachId);
        }
    }
}
