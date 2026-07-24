using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Interfaces;
using MenuGreen.DataAccessLayer.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
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

                // Suppress PendingModelChangesWarning - Query filters in OnModelCreating are
                // runtime-only and don't affect the database schema. This is a false positive
                // because EF Core doesn't snapshot query filters in migrations.
                options.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
            });

            // Register Repositories and UnitOfWork
            services.AddScoped(typeof(IGenericRepository<>), typeof(GenericRepository<>));
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            return services;
        }
    }
}
