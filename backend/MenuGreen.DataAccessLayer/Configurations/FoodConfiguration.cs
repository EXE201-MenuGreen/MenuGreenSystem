using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class FoodConfiguration : IEntityTypeConfiguration<Food>
    {
        public void Configure(EntityTypeBuilder<Food> builder)
        {
            builder.ToTable("foods");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.NameVi).IsRequired().HasColumnType("text");
            builder.Property(x => x.NameEn).HasColumnType("text");
            builder.Property(x => x.Category).HasColumnType("text");
            builder.Property(x => x.Description).HasColumnType("text");
            builder.Property(x => x.ImageUrl).HasColumnType("text");
            builder.Property(x => x.Region).HasColumnType("text");
        }
    }
}
