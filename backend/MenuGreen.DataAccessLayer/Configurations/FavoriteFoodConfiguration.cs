using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class FavoriteFoodConfiguration : IEntityTypeConfiguration<FavoriteFood>
    {
        public void Configure(EntityTypeBuilder<FavoriteFood> builder)
        {
            builder.ToTable("favorite_foods");

            builder.HasKey(x => new { x.UserId, x.FoodId });

            builder.Property(x => x.CreatedAt)
                .HasColumnType("timestamp with time zone")
                .IsRequired();

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.Food)
                .WithMany()
                .HasForeignKey(x => x.FoodId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
