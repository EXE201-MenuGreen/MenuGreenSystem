using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/admin/notifications")]
    [Authorize(Policy = "AdminOnly")]
    public class NotificationAdminController : ControllerBase
    {
        private readonly INotificationDispatcherService _dispatcher;
        private readonly INotificationService _notificationService;

        public NotificationAdminController(
            INotificationDispatcherService dispatcher,
            INotificationService notificationService)
        {
            _dispatcher = dispatcher;
            _notificationService = notificationService;
        }

        /// <summary>
        /// Manually trigger dispatch of all due notifications.
        /// </summary>
        [HttpPost("dispatch")]
        public async Task<IActionResult> DispatchNow()
        {
            var result = await _dispatcher.DispatchDueNotificationsAsync();
            return Ok(result);
        }

        /// <summary>
        /// Get pending (not yet sent) notification count.
        /// </summary>
        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingCount()
        {
            var result = await _dispatcher.GetDispatchStatsAsync();
            return Ok(new
            {
                PendingProcessed = result.TotalProcessed,
                Sent = result.PushSent,
                Failed = result.PushFailed,
                Skipped = result.Skipped
            });
        }
    }
}
