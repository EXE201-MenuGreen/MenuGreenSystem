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
    [Authorize(Policy = "UserOnly")]
    public class HealthProfileController : ControllerBase
    {
        private readonly IHealthProfileService _service;
        public HealthProfileController(IHealthProfileService service) => _service = service;

        // Xem hồ sơ sức khỏe của chính mình.
        [HttpGet("me")]
        public async Task<IActionResult> Get()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            try
            {
                return Ok(await _service.GetAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }


        /// <summary>
        /// Tính lại BMI, BMR, TDEE, target calories và macro từ dữ liệu sức khỏe hiện tại.
        /// </summary>
        [HttpPost("me/calculate")]
        public async Task<IActionResult> Calculate()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            try
            {
                return Ok(await _service.CalculateAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật riêng mục tiêu sức khỏe của user.
        /// </summary>
        [HttpPatch("me/goal")]
        public async Task<IActionResult> UpdateGoal([FromBody] UpdateHealthGoalRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateGoalAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật hồ sơ sức khỏe của chính mình.
        /// </summary>
        [HttpPut("me")]
        public async Task<IActionResult> Update([FromBody] UpdateHealthProfileRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
