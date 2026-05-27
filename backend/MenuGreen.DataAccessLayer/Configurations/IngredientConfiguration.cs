using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class IngredientConfiguration : IEntityTypeConfiguration<Ingredient>
    {
        public void Configure(EntityTypeBuilder<Ingredient> builder)
        {
            builder.ToTable("ingredients");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.NameVi).IsRequired().HasColumnType("text");
            builder.Property(x => x.NameEn).HasColumnType("text");
            builder.Property(x => x.Category).HasColumnType("text");
            builder.Property(x => x.UnitDefault).HasColumnType("text");
            builder.Property(x => x.ImageUrl).HasColumnType("text");
        }
    }
}
