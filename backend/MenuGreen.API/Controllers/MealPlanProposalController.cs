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
    [Route("api/meal-plan-proposals")]
    [Authorize]
    public class MealPlanProposalController : ControllerBase
    {
        private readonly IMealPlanProposalService _service;

        public MealPlanProposalController(IMealPlanProposalService service)
        {
            _service = service;
        }

        [HttpPost("reviews/{reviewRequestId:guid}/draft")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> CreateDraft(Guid reviewRequestId) =>
            await ExecuteAsync(userId => _service.CreateDraftAsync(userId, reviewRequestId));

        [HttpPut("{proposalId:guid}")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> UpdateDraft(
            Guid proposalId,
            [FromBody] UpdateMealPlanProposalRequest request) =>
            await ExecuteAsync(userId => _service.UpdateDraftAsync(userId, proposalId, request));

        [HttpPut("{proposalId:guid}/items/{itemId:guid}/portion")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> UpdateItemPortion(
            Guid proposalId,
            Guid itemId,
            [FromBody] UpdateMealPlanProposalItemPortionRequest request) =>
            await ExecuteAsync(userId =>
                _service.UpdateItemPortionAsync(userId, proposalId, itemId, request));

        [HttpPost("{proposalId:guid}/submit")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> Submit(Guid proposalId) =>
            await ExecuteAsync(userId => _service.SubmitAsync(userId, proposalId));

        [HttpGet("{proposalId:guid}")]
        public async Task<IActionResult> Get(Guid proposalId) =>
            await ExecuteAsync(userId => _service.GetAsync(userId, proposalId));

        [HttpGet("mine")]
        [Authorize(Policy = "GymFeatures")]
        public async Task<IActionResult> GetMine([FromQuery] string? status) =>
            await ExecuteAsync(userId => _service.GetMineAsync(userId, status));

        [HttpPost("{proposalId:guid}/apply")]
        [Authorize(Policy = "GymFeatures")]
        public async Task<IActionResult> Apply(Guid proposalId) =>
            await ExecuteAsync(userId => _service.ApplyAsync(userId, proposalId));

        [HttpPost("{proposalId:guid}/reject")]
        [Authorize(Policy = "GymFeatures")]
        public async Task<IActionResult> Reject(Guid proposalId) =>
            await ExecuteAsync(userId => _service.RejectAsync(userId, proposalId));

        private async Task<IActionResult> ExecuteAsync<T>(Func<Guid, Task<T>> action)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await action(userId));
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(raw, out userId);
        }
    }
}
