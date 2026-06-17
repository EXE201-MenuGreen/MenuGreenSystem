using MenuGreen.DataAccessLayer.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MenuGreen.DataAccessLayer.Configurations
{
    public class UserSubstitutionPreferenceConfiguration : IEntityTypeConfiguration<UserSubstitutionPreference>
    {
        public void Configure(EntityTypeBuilder<UserSubstitutionPreference> builder)
        {
            builder.ToTable("user_substitution_preferences");
            builder.HasKey(x => x.Id);

            builder.Property(x => x.CreatedAt).IsRequired();

            builder.HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.OriginalIngredient)
                .WithMany()
                .HasForeignKey(x => x.OriginalIngredientId)
                .OnDelete(DeleteBehavior.Cascade);

            builder.HasOne(x => x.SubstituteIngredient)
                .WithMany()
                .HasForeignKey(x => x.SubstituteIngredientId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
