using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class PaymentConfiguration : IEntityTypeConfiguration<Payment>
    {
        public void Configure(EntityTypeBuilder<Payment> builder)
        {
            builder.ToTable("payments");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.AmountVnd).IsRequired();
            builder.Property(x => x.Status).IsRequired().HasMaxLength(32);
            builder.Property(x => x.PaymentMethod).IsRequired().HasMaxLength(32);
            builder.Property(x => x.Provider).IsRequired().HasMaxLength(32);
            builder.Property(x => x.ProviderOrderCode).IsRequired().HasMaxLength(128);
            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasIndex(x => x.ProviderOrderCode).IsUnique();
            builder.HasIndex(x => new { x.UserId, x.CreatedAt });
            builder.HasIndex(x => x.UserSubscriptionId);
            builder.HasIndex(x => x.UserPremiumProgramId);

            builder.ToTable(t =>
                t.HasCheckConstraint("CK_payments_status", "\"Status\" IN ('PENDING','PAID','FAILED','EXPIRED','REFUNDED','CANCELLED')"));

            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
            builder.HasOne(x => x.UserSubscription).WithMany().HasForeignKey(x => x.UserSubscriptionId).OnDelete(DeleteBehavior.SetNull);
            builder.HasOne(x => x.UserPremiumProgram).WithMany().HasForeignKey(x => x.UserPremiumProgramId).OnDelete(DeleteBehavior.SetNull);
        }
    }
}
