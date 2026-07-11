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
    /// Controller for meal templates to quickly log repeated meals.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class MealTemplateController : ControllerBase
    {
        private readonly IMealTemplateService _service;

        public MealTemplateController(IMealTemplateService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAllAsync(userId));
        }

        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetByIdAsync(userId, id));
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MealTemplateUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateAsync(userId, request));
        }

        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] MealTemplateUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateAsync(userId, id, request));
        }

        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteAsync(userId, id);
            return Ok(new { Message = "Meal template deleted successfully." });
        }

        [HttpPost("{id:guid}/log")]
        public async Task<IActionResult> Log(Guid id, [FromBody] MealTemplateLogRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.LogAsync(userId, id, request));
        }

        [HttpPost("{id:guid}/duplicate")]
        public async Task<IActionResult> Duplicate(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.DuplicateAsync(userId, id));
        }

        [HttpGet("{id:guid}/usage")]
        public async Task<IActionResult> GetUsage(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(new { UsageCount = await _service.GetUsageAsync(userId, id) });
        }

        [HttpPost("from-log/{mealLogId:guid}")]
        public async Task<IActionResult> CreateFromLog(Guid mealLogId, [FromQuery] string title)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            if (string.IsNullOrWhiteSpace(title)) return BadRequest("Title is required.");
            try
            {
                return Ok(await _service.CreateFromLogAsync(userId, mealLogId, title));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
