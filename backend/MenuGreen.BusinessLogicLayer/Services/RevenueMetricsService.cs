using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Interfaces;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class RevenueMetricsService : IRevenueMetricsService
    {
        private readonly IUnitOfWork _unitOfWork;

        public RevenueMetricsService(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<RevenueDashboardMetricsResponse> GetSummaryAsync()
        {
            var transactions = await _unitOfWork.SubscriptionTransactions.GetAllAsync();
            var successTransactions = transactions.Where(x => x.Status == "Success");
            var subscribeRevenue = successTransactions.Where(x => x.TransactionType == "Subscribe").Sum(x => x.Amount);
            var renewRevenue = successTransactions.Where(x => x.TransactionType == "Renew").Sum(x => x.Amount);

            return new RevenueDashboardMetricsResponse
            {
                TotalRevenueVnd = subscribeRevenue + renewRevenue,
                SubscribeRevenueVnd = subscribeRevenue,
                RenewRevenueVnd = renewRevenue,
                TransactionCount = successTransactions.Count()
            };
        }
    }
}
