using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class RecommendationFeedbackConfiguration : IEntityTypeConfiguration<RecommendationFeedback>
    {
        public void Configure(EntityTypeBuilder<RecommendationFeedback> builder)
        {
            builder.ToTable("recommendation_feedbacks");

            builder.HasKey(x => x.Id);

            builder.Property(x => x.Rating)
                .IsRequired(false);

            builder.Property(x => x.Feedback)
                .HasColumnType("text");

            builder.Property(x => x.CreatedAt)
                .HasColumnType("timestamp with time zone");

            builder.HasOne(x => x.Recommendation)
                .WithMany()
                .HasForeignKey(x => x.RecommendationId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => x.RecommendationId);
        }
    }
}
