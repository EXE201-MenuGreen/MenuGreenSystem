using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller quản lý User Subscription - Đăng ký gói thành viên.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class UserSubscriptionController : ControllerBase
    {
        private readonly IUserSubscriptionService _service;
        private readonly ISubscriptionPlanService _planService;

        public UserSubscriptionController(
            IUserSubscriptionService service,
            ISubscriptionPlanService planService)
        {
            _service = service;
            _planService = planService;
        }

        /// <summary>
        /// Lấy danh sách gói subscription đang hoạt động để user chọn đăng ký.
        /// </summary>
        [HttpGet("plans")]
        public async Task<IActionResult> GetAvailablePlans()
        {
            return Ok(await _planService.GetAllAsync(isActive: true));
        }

        /// <summary>
        /// Đăng ký mới một gói thành viên cho user hiện tại.
        /// </summary>
        [HttpPost("subscribe")]
        public async Task<IActionResult> Subscribe([FromBody] SubscribeRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                return Ok(await _service.SubscribeAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Gia hạn gói thành viên hiện tại.
        /// </summary>
        [HttpPost("renew")]
        public async Task<IActionResult> Renew([FromBody] RenewSubscriptionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                return Ok(await _service.RenewAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Hủy gói thành viên trước thời hạn.
        /// </summary>
        [HttpPost("cancel")]
        public async Task<IActionResult> Cancel([FromBody] CancelSubscriptionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                return Ok(await _service.CancelAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy gói thành viên hiện tại của user.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrent()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetCurrentAsync(userId));
        }

        /// <summary>
        /// Xem chi tiết một subscription cụ thể theo ID.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            
            try
            {
                return Ok(await _service.GetByIdAsync(userId, id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy toàn bộ lịch sử giao dịch đăng ký/gia hạn/hủy của user.
        /// </summary>
        [HttpGet("me/history")]
        public async Task<IActionResult> GetHistory()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetHistoryAsync(userId));
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
