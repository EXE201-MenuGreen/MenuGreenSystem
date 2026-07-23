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
    /// Controller for managing User Budget Requests.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class BudgetRequestController : ControllerBase
    {
        private readonly IBudgetRequestService _service;

        public BudgetRequestController(IBudgetRequestService service)
        {
            _service = service;
        }

        /// <summary>
        /// Get active (most recent) budget request of current user.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetActive()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetActiveBudgetAsync(userId);
            if (result == null) return NotFound(new { Message = "No budget configuration found." });
            return Ok(result);
        }

        /// <summary>
        /// Set desired food budget and cooking time limits.
        /// </summary>
        [HttpPost]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> Create([FromBody] BudgetRequestUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateAsync(userId, request));
        }

        /// <summary>
        /// Update budget or cooking time limit by Id.
        /// </summary>
        [HttpPut("{id:guid}")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> Update(Guid id, [FromBody] BudgetRequestUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateAsync(userId, id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Delete configured budget.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteAsync(userId, id);
                return Ok(new { Message = "Budget configuration deleted successfully." });
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
