using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class PtReviewRequestConfiguration : IEntityTypeConfiguration<PtReviewRequest>
    {
        public void Configure(EntityTypeBuilder<PtReviewRequest> builder)
        {
            builder.ToTable("PtReviewRequests");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.ReviewToken).IsRequired().HasMaxLength(100);
            builder.Property(x => x.Status).IsRequired().HasMaxLength(20);
            builder.Property(x => x.ReportDataJson).IsRequired();
            builder.Property(x => x.PtComment).HasMaxLength(1000);

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
