using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class MealPlanController : ControllerBase
    {
        private readonly IMealPlanService _service;

        public MealPlanController(IMealPlanService service)
        {
            _service = service;
        }

        /// <summary>
        /// Get current user meal plans, can filter by active status.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] bool? isActive = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAllAsync(isActive, userId));
        }

        /// <summary>
        /// Get details of a specific meal plan by Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetByIdAsync(id, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Create a new meal plan for the current user.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreateAsync(request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Create an empty meal plan (no items) - user creates plan first, adds items later.
        /// </summary>
        [HttpPost("empty")]
        public async Task<IActionResult> CreateEmpty([FromBody] CreateEmptyPlanRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreateEmptyAsync(request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }


        /// <summary>
        /// Update current meal plan information.
        /// </summary>
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateAsync(id, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Delete a meal plan by Id.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteAsync(id, userId);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Update active status of a meal plan.
        /// </summary>
        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] MealPlanStatusRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateStatusAsync(id, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Distribute meal plan to target audience.
        /// </summary>
        [HttpPost("{id:guid}/distribute")]
        public async Task<IActionResult> Distribute(Guid id, [FromQuery] string targetAudience, [FromQuery] string? notes = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.DistributeAsync(id, targetAudience, notes, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Add a new item or meal to a meal plan.
        /// </summary>
        [HttpPost("{planId:guid}/items")]
        public async Task<IActionResult> AddItem(Guid planId, [FromBody] MealPlanItemUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.AddItemAsync(planId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Update an existing item in the meal plan.
        /// </summary>
        [HttpPut("{planId:guid}/items/{itemId:guid}")]
        public async Task<IActionResult> UpdateItem(Guid planId, Guid itemId, [FromBody] MealPlanItemUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateItemAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Remove an item from a meal plan.
        /// </summary>
        [HttpDelete("{planId:guid}/items/{itemId:guid}")]
        public async Task<IActionResult> DeleteItem(Guid planId, Guid itemId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteItemAsync(planId, itemId, userId);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Update item status in meal plan.
        /// </summary>
        [HttpPatch("{planId:guid}/items/{itemId:guid}/status")]
        public async Task<IActionResult> UpdateItemStatus(Guid planId, Guid itemId, [FromBody] MealPlanStatusRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.UpdateItemStatusAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Convert meal plan item to actual meal log.
        /// </summary>
        [HttpPost("{planId:guid}/items/{itemId:guid}/convert-to-log")]
        public async Task<IActionResult> ConvertToLog(Guid planId, Guid itemId, [FromBody] MealPlanConvertToLogRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.ConvertItemToLogAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Save an AI-scanned meal as both an Office plan item and an actual meal log.
        /// </summary>
        [HttpPost("{planId:guid}/scan-meals")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> SaveScanMeal(Guid planId, [FromBody] OfficeScanMealRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SaveOfficeScanMealAsync(planId, request, userId));
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Replace one planned item with an approved Food or Recipe alternative.
        /// </summary>
        [HttpPost("{planId:guid}/items/{itemId:guid}/replace")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> ReplaceItem(Guid planId, Guid itemId, [FromBody] MealPlanItemReplaceRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.ReplaceItemAsync(planId, itemId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Save an AI-scanned dish as a planned Office meal. It is not logged as eaten.
        /// </summary>
        [HttpPost("{planId:guid}/scan-plan-items")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> SaveScanPlanItem(Guid planId, [FromBody] OfficeScanMealRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SaveOfficeScanPlanItemAsync(planId, request, userId, false));
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Save today's AI-scanned lunch as the user's Office priority lunch.
        /// </summary>
        [HttpPost("{planId:guid}/priority-lunch")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> SavePriorityLunch(Guid planId, [FromBody] OfficeScanMealRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.SaveOfficeScanPlanItemAsync(planId, request, userId, true));
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Commit today's meal plan for dashboard and reporting.
        /// </summary>
        [HttpPost("{planId:guid}/commit")]
        public async Task<IActionResult> Commit(Guid planId, [FromBody] MealPlanCommitRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CommitAsync(planId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Duplicate meal plan to a new date range.
        /// </summary>
        [HttpPost("{planId:guid}/duplicate")]
        public async Task<IActionResult> Duplicate(Guid planId, [FromBody] MealPlanDuplicateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.DuplicateAsync(planId, request, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get daily dashboard: planned meals, actual meal logs, and completion rate.
        /// </summary>
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboard([FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetDashboardAsync(date, userId));
        }

        /// <summary>
        /// Compare planned vs actual for a date range.
        /// </summary>
        [HttpGet("compare")]
        public async Task<IActionResult> GetCompare([FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetCompareAsync(from, to, userId));
        }

        /// <summary>
        /// Statistics on plan adherence over consecutive days.
        /// </summary>
        [HttpGet("streaks")]
        public async Task<IActionResult> GetStreaks()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetStreaksAsync(userId));
        }

        /// <summary>
        /// Auto-generate weekly budget-friendly menu based on user's latest budget requirements.
        /// </summary>
        [HttpPost("generate-by-budget")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> GenerateByBudget()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GenerateByBudgetAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get cost comparison of current meal plan against user budget.
        /// </summary>
        [HttpGet("{id:guid}/budget-status")]
        public async Task<IActionResult> GetBudgetStatus(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetBudgetStatusAsync(id, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Aggregate recipe ingredients into one shopping list for a lunchbox/weekly plan.</summary>
        [HttpGet("{id:guid}/grocery-list")]
        public async Task<IActionResult> GetGroceryList(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try { return Ok(await _service.GetGroceryListAsync(id, userId)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>
        /// Suggest cheaper alternative meals/recipes for items in the plan.
        /// </summary>
        [HttpGet("{planId:guid}/alternatives/{itemId:guid}")]
        public async Task<IActionResult> GetAlternatives(Guid planId, Guid itemId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetAlternativesAsync(planId, itemId, userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Compare actual food expenses (meal logs) with planned costs and set budget.
        /// </summary>
        [HttpGet("compare-expenses")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> CompareExpenses([FromQuery] DateOnly from, [FromQuery] DateOnly to)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CompareExpensesAsync(from, to, userId));
        }

        /// <summary>
        /// Analyze expense distribution by food category and suggest savings.
        /// </summary>
        [HttpGet("expense-breakdown")]
        [Authorize(Policy = "OfficeFeatures")]
        public async Task<IActionResult> GetExpenseBreakdown()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetExpenseBreakdownAsync(userId));
        }

        /// <summary>
        /// Calculate budget adherence score over recent days for user.
        /// </summary>
        [HttpGet("adherence-scores")]
        public async Task<IActionResult> GetAdherenceScores()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAdherenceScoresAsync(userId));
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
