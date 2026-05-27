using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class AiConversationConfiguration : IEntityTypeConfiguration<AiConversation>
    {
        public void Configure(EntityTypeBuilder<AiConversation> builder)
        {
            builder.ToTable("ai_conversations");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Title).HasColumnType("text");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
            builder.HasMany(x => x.Messages).WithOne(x => x.Conversation).HasForeignKey(x => x.ConversationId);
        }
    }
}
