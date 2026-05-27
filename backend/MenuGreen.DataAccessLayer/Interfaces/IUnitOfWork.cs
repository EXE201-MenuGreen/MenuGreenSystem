namespace MenuGreen.DataAccessLayer.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        IGenericRepository<Entities.User> Users { get; }
        IGenericRepository<Entities.Profile> Profiles { get; }
        IGenericRepository<Entities.Session> Sessions { get; }
        IGenericRepository<Entities.Role> Roles { get; }
        IGenericRepository<Entities.HealthProfile> HealthProfiles { get; }
        
        Task<int> CompleteAsync();
    }
}
