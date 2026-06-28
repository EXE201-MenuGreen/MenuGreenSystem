using System;
using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class DefaultPortionUnitConfiguration : IEntityTypeConfiguration<DefaultPortionUnit>
    {
        public void Configure(EntityTypeBuilder<DefaultPortionUnit> builder)
        {
            builder.ToTable("default_portion_units");
            builder.HasKey(x => x.Id);
            builder.Property(x => x.UnitName).IsRequired().HasMaxLength(150);
            builder.Property(x => x.GramsEquivalent).HasPrecision(18, 2);
            builder.Property(x => x.Description).HasMaxLength(500);

            builder.HasIndex(x => x.UnitName).IsUnique();

        }
    }
}
