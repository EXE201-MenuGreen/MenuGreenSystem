using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class SepayTransactionConfiguration : IEntityTypeConfiguration<SepayTransaction>
    {
        public void Configure(EntityTypeBuilder<SepayTransaction> builder)
        {
            builder.ToTable("sepay_transactions");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.TransactionCode).IsRequired().HasMaxLength(128);
            builder.Property(x => x.BankAccount).HasMaxLength(64);
            builder.Property(x => x.TransferAmount).IsRequired();
            builder.Property(x => x.TransferContent).IsRequired().HasMaxLength(256);
            builder.Property(x => x.TransactionTime).IsRequired();
            builder.Property(x => x.Status).IsRequired().HasMaxLength(32);
            builder.Property(x => x.RawPayloadJson).HasColumnType("text");
            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasIndex(x => x.TransactionCode).IsUnique();
            builder.HasIndex(x => x.TransferContent);
            builder.HasIndex(x => new { x.PaymentId, x.TransactionTime });

            builder.HasOne(x => x.Payment).WithMany().HasForeignKey(x => x.PaymentId);
        }
    }
}
