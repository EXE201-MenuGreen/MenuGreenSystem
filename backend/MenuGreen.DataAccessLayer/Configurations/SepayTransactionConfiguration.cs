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
            builder.Property(x => x.TransactionCode).HasColumnType("text");
            builder.Property(x => x.BankAccount).HasColumnType("text");
            builder.Property(x => x.TransferContent).HasColumnType("text");
            builder.Property(x => x.Status).HasColumnType("text");
            builder.HasOne(x => x.Payment).WithMany().HasForeignKey(x => x.PaymentId);
        }
    }
}
