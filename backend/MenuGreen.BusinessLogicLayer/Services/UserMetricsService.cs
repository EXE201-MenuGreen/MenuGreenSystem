using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class UserMetricsService : IUserMetricsService
    {
        private readonly IUnitOfWork _unitOfWork;

        public UserMetricsService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<UserDashboardMetricsResponse> GetSummaryAsync()
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            return new UserDashboardMetricsResponse
            {
                TotalUsers = users.Count(),
                ActiveUsers = users.Count(x => x.IsActive)
            };
        }
    }
}