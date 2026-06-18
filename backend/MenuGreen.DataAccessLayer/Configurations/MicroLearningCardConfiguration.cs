using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class MicroLearningCardConfiguration : IEntityTypeConfiguration<MicroLearningCard>
    {
        public void Configure(EntityTypeBuilder<MicroLearningCard> builder)
        {
            builder.ToTable("micro_learning_cards");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Title).IsRequired().HasMaxLength(255);
            builder.Property(x => x.Summary).IsRequired().HasColumnType("text");
            builder.Property(x => x.Category).IsRequired().HasMaxLength(100);
            builder.Property(x => x.Tips).HasColumnType("text");
            builder.Property(x => x.ImageUrl).HasMaxLength(500);
            builder.Property(x => x.QuizQuestion).HasColumnType("text");
            builder.Property(x => x.QuizOptions).HasColumnType("text");
            builder.Property(x => x.IsActive).HasDefaultValue(true);
        }
    }
}
