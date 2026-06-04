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
    public class UserAiProfileController : ControllerBase
    {
        private readonly IUserAiProfileService _service;

        public UserAiProfileController(IUserAiProfileService service) => _service = service;

        [HttpGet("me")]
        public async Task<IActionResult> Get()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPut("me")]
        public async Task<IActionResult> Upsert([FromBody] UpdateUserAiProfileRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpsertAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(raw, out userId);
        }
    }
}
