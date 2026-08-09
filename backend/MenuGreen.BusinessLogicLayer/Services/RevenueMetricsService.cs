using System;
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

        public async Task<RevenueTimeSeriesResponse> GetTimeSeriesAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var allTransactions = await _unitOfWork.SubscriptionTransactions.GetAllAsync();
            var successTransactions = allTransactions
                .Where(x => x.Status == "Success" && x.TransactionDate >= from && x.TransactionDate <= to)
                .ToList();

            // Calculate previous period for comparison
            var periodLength = to - from;
            var previousFrom = from.AddDays(-periodLength.TotalDays);
            var previousTo = from.AddDays(-1);
            var previousTransactions = allTransactions
                .Where(x => x.Status == "Success" && x.TransactionDate >= previousFrom && x.TransactionDate <= previousTo)
                .Sum(x => x.Amount);

            // Group by date
            var groupedByDate = successTransactions
                .GroupBy(x => x.TransactionDate.Date)
                .OrderBy(x => x.Key)
                .Select(g => new RevenueTimeSeriesPoint
                {
                    Date = g.Key,
                    TotalRevenue = g.Sum(x => x.Amount),
                    SubscribeRevenue = g.Where(x => x.TransactionType == "Subscribe").Sum(x => x.Amount),
                    RenewRevenue = g.Where(x => x.TransactionType == "Renew").Sum(x => x.Amount),
                    TransactionCount = g.Count()
                })
                .ToList();

            var totalRevenue = successTransactions.Sum(x => x.Amount);
            var changeVsPrevious = previousTransactions > 0
                ? Math.Round((double)(totalRevenue - previousTransactions) / previousTransactions * 100, 1)
                : 0;

            return new RevenueTimeSeriesResponse
            {
                Points = groupedByDate,
                TotalRevenue = totalRevenue,
                TransactionCount = successTransactions.Count,
                ChangeVsPrevious = changeVsPrevious
            };
        }

        public async Task<RevenueByPlanResponse> GetByPlanAsync(DateTimeOffset from, DateTimeOffset to)
        {
            var allTransactions = await _unitOfWork.SubscriptionTransactions.GetAllAsync();
            var successTransactions = allTransactions
                .Where(x => x.Status == "Success" && x.TransactionDate >= from && x.TransactionDate <= to)
                .ToList();

            var subscriptions = await _unitOfWork.UserSubscriptions.GetAllAsync();
            var plans = await _unitOfWork.SubscriptionPlans.GetAllAsync();

            // Plan colors
            var planColors = new[]
            {
                "#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"
            };

            var planGroups = successTransactions
                .Join(subscriptions, t => t.UserSubscriptionId, s => s.Id, (t, s) => new { t, s })
                .Join(plans, ts => ts.s.SubscriptionPlanId, p => p.Id, (ts, p) => new { ts.t, Plan = p })
                .GroupBy(x => new { x.Plan.Id, x.Plan.Name, x.Plan.FeatureGroup })
                .Select((g, index) => new RevenueByPlanItem
                {
                    PlanName = g.Key.Name ?? "Unknown",
                    PlanKey = g.Key.FeatureGroup ?? "unknown",
                    Revenue = g.Sum(x => x.t.Amount),
                    Subscribers = g.Select(x => x.t.UserId).Distinct().Count(),
                    Percent = 0, // Will calculate after
                    Color = planColors[index % planColors.Length]
                })
                .OrderByDescending(x => x.Revenue)
                .ToList();

            var totalRevenue = planGroups.Sum(x => x.Revenue);
            foreach (var plan in planGroups)
            {
                plan.Percent = totalRevenue > 0 ? Math.Round((double)plan.Revenue / totalRevenue * 100, 1) : 0;
            }

            return new RevenueByPlanResponse
            {
                Plans = planGroups,
                TotalRevenue = totalRevenue,
                TotalSubscribers = planGroups.Sum(x => x.Subscribers)
            };
        }
    }
}
