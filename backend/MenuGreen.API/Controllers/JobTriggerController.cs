using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Hosting;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using System;
using MenuGreen.BusinessLogicLayer.Services;
using MenuGreen.BusinessLogicLayer.BackgroundJobs;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Admin controller to manually trigger background jobs for verification.
    /// </summary>
    [Authorize(Roles = "Admin")]
    [ApiController]
    [Route("api/admin/jobs")]
    public class JobTriggerController : ControllerBase
    {
        private readonly IEnumerable<IHostedService> _hostedServices;

        public JobTriggerController(IEnumerable<IHostedService> hostedServices)
        {
            _hostedServices = hostedServices;
        }

        /// <summary>
        /// Manually trigger a background job's business logic execution immediately.
        /// </summary>
        /// <param name="jobName">Name of the job (SubscriptionExpiration, StreakReset, GoalDrift, SepayReconciliation, DailyStarter)</param>
        [HttpPost("trigger/{jobName}")]
        public async Task<IActionResult> TriggerJob(string jobName)
        {
            var cancellationToken = HttpContext.RequestAborted;

            if (string.Equals(jobName, "SubscriptionExpiration", StringComparison.OrdinalIgnoreCase))
            {
                var service = _hostedServices.OfType<SubscriptionExpirationBackgroundService>().FirstOrDefault();
                if (service == null) return NotFound("Job not found.");
                await service.ExpireSubscriptionsAsync(cancellationToken);
                return Ok("Subscription expiration job triggered successfully.");
            }
            
            if (string.Equals(jobName, "StreakReset", StringComparison.OrdinalIgnoreCase))
            {
                var service = _hostedServices.OfType<StreakResetBackgroundService>().FirstOrDefault();
                if (service == null) return NotFound("Job not found.");
                await service.CheckBrokenStreaksAsync(cancellationToken);
                return Ok("Streak reset job triggered successfully.");
            }

            if (string.Equals(jobName, "GoalDrift", StringComparison.OrdinalIgnoreCase))
            {
                var service = _hostedServices.OfType<GoalDriftDetectionBackgroundService>().FirstOrDefault();
                if (service == null) return NotFound("Job not found.");
                await service.ScanGoalDriftsAsync(cancellationToken);
                return Ok("Goal drift detection job triggered successfully.");
            }

            if (string.Equals(jobName, "SepayReconciliation", StringComparison.OrdinalIgnoreCase))
            {
                var service = _hostedServices.OfType<SepayReconciliationBackgroundService>().FirstOrDefault();
                if (service == null) return NotFound("Job not found.");
                await service.ReconcilePaymentsAsync(cancellationToken);
                return Ok("SePay reconciliation job triggered successfully.");
            }

            if (string.Equals(jobName, "DailyStarter", StringComparison.OrdinalIgnoreCase))
            {
                var service = _hostedServices.OfType<DailyStarterBackgroundService>().FirstOrDefault();
                if (service == null) return NotFound("Job not found.");
                await service.PreCalculateDailyStarterAsync(cancellationToken);
                return Ok("Daily starter pre-calculation job triggered successfully.");
            }

            return BadRequest($"Unknown job name: {jobName}. Supported jobs: SubscriptionExpiration, StreakReset, GoalDrift, SepayReconciliation, DailyStarter");
        }
    }
}
