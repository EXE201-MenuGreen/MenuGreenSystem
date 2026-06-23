using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserCardInteractionConfiguration : IEntityTypeConfiguration<UserCardInteraction>
    {
        public void Configure(EntityTypeBuilder<UserCardInteraction> builder)
        {
            builder.ToTable("user_card_interactions");
            builder.HasKey(x => x.Id);
            
            // Relationships
            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.MicroLearningCard)
                .WithMany(c => c.UserCardInteractions)
                .HasForeignKey(x => x.CardId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasIndex(x => new { x.UserId, x.CardId }).IsUnique();
        }
    }
}
