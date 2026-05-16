namespace MenuGreen.DataAccessLayer.Interfaces
{
    public interface IUnitOfWork : IDisposable
    {
        IGenericRepository<Entities.User> Users { get; }
        IGenericRepository<Entities.Profile> Profiles { get; }
        IGenericRepository<Entities.Session> Sessions { get; }
        
        Task<int> CompleteAsync();
    }
}
