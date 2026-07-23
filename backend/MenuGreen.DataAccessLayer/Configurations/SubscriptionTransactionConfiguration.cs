using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class SubscriptionTransactionConfiguration : IEntityTypeConfiguration<SubscriptionTransaction>
    {
        public void Configure(EntityTypeBuilder<SubscriptionTransaction> builder)
        {
            builder.ToTable("subscription_transactions");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.Id).ValueGeneratedNever();

            builder.Property(x => x.TransactionType).IsRequired().HasMaxLength(50);
            builder.Property(x => x.Status).IsRequired().HasMaxLength(50);
            builder.Property(x => x.Note).HasColumnType("text");
            builder.Property(x => x.TransactionDate).IsRequired();
            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasIndex(x => x.UserId);
            builder.HasIndex(x => x.UserSubscriptionId);
            builder.HasIndex(x => x.TransactionDate);

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.UserSubscription)
                .WithMany()
                .HasForeignKey(x => x.UserSubscriptionId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_sub_txn_user_sub");
        }
    }
}
