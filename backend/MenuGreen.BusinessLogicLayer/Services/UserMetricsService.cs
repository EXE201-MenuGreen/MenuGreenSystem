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
            var subscriptions = await _unitOfWork.UserSubscriptions.GetAllAsync();

            var premiumPlanIds = (await _unitOfWork.SubscriptionPlans.FindAsync(x => x.Name == "Premium" && x.IsActive == true)).Select(x => x.Id).ToHashSet();
            var proPlanIds = (await _unitOfWork.SubscriptionPlans.FindAsync(x => x.Name == "Pro" && x.IsActive == true)).Select(x => x.Id).ToHashSet();

            var activeSubscriptions = subscriptions.Where(x => x.Status == "Active");

            return new UserDashboardMetricsResponse
            {
                TotalUsers = users.Count(),
                ActiveUsers = users.Count(x => x.IsActive),
                PremiumUsers = activeSubscriptions.Count(x => premiumPlanIds.Contains(x.SubscriptionPlanId)),
                ProUsers = activeSubscriptions.Count(x => proPlanIds.Contains(x.SubscriptionPlanId))
            };
        }
    }
}
