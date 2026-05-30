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
            return Ok(await _service.GetAsync(id));
        }

        // Cập nhật hồ sơ sức khỏe của chính mình.
        [HttpPut("me")]
        public async Task<IActionResult> Update([FromBody] UpdateHealthProfileRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            return Ok(await _service.UpdateAsync(id, request));
        }
    }
}
