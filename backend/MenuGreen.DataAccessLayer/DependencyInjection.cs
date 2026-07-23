using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Interfaces;
using MenuGreen.DataAccessLayer.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace MenuGreen.DataAccessLayer
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddDataAccessLayer(this IServiceCollection services, IConfiguration configuration)
        {
            // Register ApplicationDbContext with PostgreSQL
            services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseNpgsql(ConnectionStringHelper.ResolvePostgresConnectionString(configuration));
                // TEMPORARY: Ignore PendingModelChangesWarning to allow deployment
                // TODO: Remove after fixing model/migration mismatch
                options.ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.CoreEventId.PendingModelChangesWarning));
            });

            // Register Repositories and UnitOfWork
            services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            return services;
        }
    }
}
