using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserSubscriptionController : ControllerBase
    {
        private readonly IUserSubscriptionService _service;

        public UserSubscriptionController(IUserSubscriptionService service)
        {
            _service = service;
        }

        // Đăng ký mới một gói thành viên cho user hiện tại.
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

        // Gia hạn gói thành viên hiện tại.
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

        // Hủy gói thành viên trước thời hạn.
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

        // Lấy gói thành viên hiện tại của user.
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrent()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetCurrentAsync(userId));
        }

        // Lấy toàn bộ lịch sử giao dịch đăng ký/gia hạn/hủy của user.
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
