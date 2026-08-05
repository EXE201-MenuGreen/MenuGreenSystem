using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class CoachChatMessageConfiguration : IEntityTypeConfiguration<CoachChatMessage>
    {
        public void Configure(EntityTypeBuilder<CoachChatMessage> builder)
        {
            builder.ToTable("coach_chat_messages");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.Content)
                .HasMaxLength(2000)
                .IsRequired();
            builder.Property(x => x.SentAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();
            builder.Property(x => x.ReadAt)
                .HasColumnType("timestamp with time zone");

            builder.HasIndex(x => new { x.SenderId, x.ReceiverId, x.SentAt });
            builder.HasIndex(x => new { x.ReceiverId, x.ReadAt });

            builder.HasOne(x => x.Sender)
                .WithMany()
                .HasForeignKey(x => x.SenderId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.Receiver)
                .WithMany()
                .HasForeignKey(x => x.ReceiverId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
