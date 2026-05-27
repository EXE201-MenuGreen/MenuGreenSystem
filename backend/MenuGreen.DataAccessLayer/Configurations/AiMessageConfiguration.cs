using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class AiMessageConfiguration : IEntityTypeConfiguration<AiMessage>
    {
        public void Configure(EntityTypeBuilder<AiMessage> builder)
        {
            builder.ToTable("ai_messages");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Role).HasColumnType("text");
            builder.Property(x => x.Content).HasColumnType("text");
            builder.HasOne(x => x.Conversation).WithMany(x => x.Messages).HasForeignKey(x => x.ConversationId);
        }
    }
}
