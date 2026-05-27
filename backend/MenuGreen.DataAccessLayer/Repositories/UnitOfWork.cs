using MenuGreen.DataAccessLayer.Context;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.DataAccessLayer.Repositories
{
    public class UnitOfWork : IUnitOfWork
    {
        private readonly ApplicationDbContext _context;
        
        private IGenericRepository<Entities.User>? _users;
        private IGenericRepository<Entities.Profile>? _profiles;
        private IGenericRepository<Entities.Session>? _sessions;
        private IGenericRepository<Entities.Role>? _roles;
        private IGenericRepository<Entities.HealthProfile>? _healthProfiles;

        public UnitOfWork(ApplicationDbContext context)
        {
            _context = context;
        }

        public IGenericRepository<Entities.User> Users => _users ??= new GenericRepository<Entities.User>(_context);
        public IGenericRepository<Entities.Profile> Profiles => _profiles ??= new GenericRepository<Entities.Profile>(_context);
        public IGenericRepository<Entities.Session> Sessions => _sessions ??= new GenericRepository<Entities.Session>(_context);
        public IGenericRepository<Entities.Role> Roles => _roles ??= new GenericRepository<Entities.Role>(_context);
        public IGenericRepository<Entities.HealthProfile> HealthProfiles => _healthProfiles ??= new GenericRepository<Entities.HealthProfile>(_context);

        public async Task<int> CompleteAsync()
        {
            return await _context.SaveChangesAsync();
        }

        public void Dispose()
        {
            _context.Dispose();
            GC.SuppressFinalize(this);
        }
    }
}
