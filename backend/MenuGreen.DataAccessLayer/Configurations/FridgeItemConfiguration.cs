using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class FridgeItemConfiguration : IEntityTypeConfiguration<FridgeItem>
    {
        public void Configure(EntityTypeBuilder<FridgeItem> builder)
        {
            builder.ToTable("fridge_items");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.CustomName).HasColumnType("text");
            builder.Property(x => x.Unit).HasColumnType("text");
            builder.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId);
            builder.HasOne(x => x.Ingredient).WithMany().HasForeignKey(x => x.IngredientId);
        }
    }
}
