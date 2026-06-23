using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class CoachFeedbackConfiguration : IEntityTypeConfiguration<CoachFeedback>
    {
        public void Configure(EntityTypeBuilder<CoachFeedback> builder)
        {
            builder.ToTable("coach_feedbacks");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.FeedbackType).IsRequired().HasMaxLength(50);
            builder.Property(x => x.MealType).HasMaxLength(50);
            builder.Property(x => x.Content).IsRequired().HasColumnType("text");

            builder.HasOne(x => x.Client)
                .WithMany()
                .HasForeignKey(x => x.ClientId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.Coach)
                .WithMany()
                .HasForeignKey(x => x.CoachId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(x => x.ClientId);
            builder.HasIndex(x => x.CoachId);
        }
    }
}
