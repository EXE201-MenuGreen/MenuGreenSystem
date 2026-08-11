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
    [Route("api/Coaches")]
    public class CoachesController : ControllerBase
    {
        private readonly ICoachService _coachService;

        public CoachesController(ICoachService coachService)
        {
            _coachService = coachService;
        }

        /// <summary>Filter and search list of coaches/experts.</summary>
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetCoaches(
            [FromQuery] string? specialty,
            [FromQuery] int? minPrice,
            [FromQuery] int? maxPrice)
        {
            try
            {
                var result = await _coachService.GetCoachesAsync(specialty, minPrice, maxPrice);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>View detailed profile of a Coach.</summary>
        [HttpGet("{id:guid}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCoachById(Guid id)
        {
            try
            {
                var result = await _coachService.GetCoachByIdAsync(id);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Register to upgrade account to expert Coach role.</summary>
        [HttpPost("register")]
        [Authorize]
        public async Task<IActionResult> RegisterCoach([FromBody] CoachRegisterRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.RegisterCoachAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get the signed-in PT application, including draft and review status.</summary>
        [HttpGet("application/me")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetMyApplication()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try { return Ok(await _coachService.GetMyApplicationAsync(userId)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>Save an incomplete PT application without submitting it.</summary>
        [HttpPut("application/me")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> SaveMyApplicationDraft(
            [FromBody] CoachApplicationUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try { return Ok(await _coachService.SaveApplicationDraftAsync(userId, request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>Submit or resubmit a completed PT application for Admin review.</summary>
        [HttpPost("application/me/submit")]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> SubmitMyApplication(
            [FromBody] CoachApplicationUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try { return Ok(await _coachService.SubmitApplicationAsync(userId, request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>Admin lists PT applications, optionally filtered by status.</summary>
        [HttpGet("admin/applications")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetApplicationsForAdmin([FromQuery] string? status)
        {
            try { return Ok(await _coachService.GetApplicationsForAdminAsync(status)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>Admin views all private verification details of one PT application.</summary>
        [HttpGet("admin/applications/{id:guid}")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> GetApplicationForAdmin(Guid id)
        {
            try { return Ok(await _coachService.GetApplicationForAdminAsync(id)); }
            catch (Exception ex) { return NotFound(new { Message = ex.Message }); }
        }

        /// <summary>Admin approves, requests revision, rejects or suspends a PT application.</summary>
        [HttpPost("admin/applications/{id:guid}/review")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> ReviewApplication(
            Guid id,
            [FromBody] CoachApplicationReviewRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var adminUserId)) return Unauthorized();
            try { return Ok(await _coachService.ReviewApplicationAsync(adminUserId, id, request)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>Student sends request to connect with a Coach.</summary>
        [HttpPost("connect/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "CoachAccessOnly")]
        public async Task<IActionResult> ConnectCoach(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.ConnectCoachAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Connection request sent to Coach." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach approves or rejects student connection request.</summary>
        [HttpPost("approve-connection/{clientId:guid}")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> ApproveConnection(Guid clientId, [FromBody] CoachApproveConnectionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.ApproveConnectionAsync(userId, clientId, request.Approve);
                return Ok(new { Success = result, Message = request.Approve ? "Student connection approved." : "Student connection rejected." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach gets list of students currently connected to them.</summary>
        [HttpGet("my-clients")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetMyClients()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetMyClientsAsync(userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("my-coaches")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyCoaches()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try { return Ok(await _coachService.GetMyCoachesAsync(userId)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        [HttpGet("my-feedback")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyFeedback()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try { return Ok(await _coachService.GetFeedbacksAsync(userId)); }
            catch (Exception ex) { return BadRequest(new { Message = ex.Message }); }
        }

        /// <summary>Student grants health data access to Coach.</summary>
        [HttpPost("grant-access/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GrantAccess(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GrantAccessAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Data access granted to Coach." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("revoke-access/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> RevokeAccess(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.RevokeAccessAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Coach data access revoked." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Student disconnects from Coach (removes connection).</summary>
        [HttpPost("disconnect/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> DisconnectCoach(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.DisconnectCoachAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Successfully disconnected from Coach." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach views student body metrics, goals, and allergies.</summary>
        [HttpGet("clients/{clientId:guid}/profile")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientProfile(Guid clientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientProfileAsync(userId, clientId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach views actual nutrition intake summary of student.</summary>
        [HttpGet("clients/{clientId:guid}/nutrition-summary")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientNutritionSummary(Guid clientId, [FromQuery] int days = 7)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientNutritionSummaryAsync(userId, clientId, days);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach views actual weight trend of student.</summary>
        [HttpGet("clients/{clientId:guid}/weight-trend")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientWeightTrend(Guid clientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientWeightTrendAsync(userId, clientId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach sends feedback/review for student.</summary>
        [HttpPost("clients/{clientId:guid}/feedback")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> AddFeedback(Guid clientId, [FromBody] CoachFeedbackCreateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.AddFeedbackAsync(userId, clientId, request);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Student (or Coach) gets list of feedback/responses.</summary>
        [HttpGet("clients/{clientId:guid}/feedback")]
        [Authorize]
        public async Task<IActionResult> GetFeedbacks(Guid clientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                if (userId != clientId)
                {
                    var connection = (await _coachService.GetMyClientsAsync(userId));
                    bool isConnected = false;
                    foreach (var c in connection)
                    {
                        if (c.ClientId == clientId) isConnected = true;
                    }
                    if (!isConnected) return StatusCode(403, new { Message = "You do not have access to this student's feedback." });
                }

                var result = await _coachService.GetFeedbacksAsync(clientId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach adjusts/modifies student's meal plan.</summary>
        [HttpPut("clients/{clientId:guid}/meal-plan/{planId:guid}")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> AdjustClientMealPlan(Guid clientId, Guid planId, [FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.AdjustClientMealPlanAsync(userId, clientId, planId, request);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach directly updates student's Calo/Macros targets.</summary>
        [HttpPut("clients/{clientId:guid}/health-targets")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> AdjustClientHealthTargets(Guid clientId, [FromBody] ClientHealthTargetsAdjustRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.AdjustClientHealthTargetsAsync(userId, clientId, request);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach gets history list of client meal plans.</summary>
        [HttpGet("clients/{clientId:guid}/meal-plans")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientMealPlans(
            Guid clientId,
            [FromQuery] DateOnly? from,
            [FromQuery] DateOnly? to,
            [FromQuery] string? planType)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientMealPlansAsync(userId, clientId, from, to, planType);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach gets single client meal plan detail.</summary>
        [HttpGet("clients/{clientId:guid}/meal-plans/{planId:guid}")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientMealPlanDetail(Guid clientId, Guid planId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientMealPlanDetailAsync(userId, clientId, planId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach creates a new meal plan on behalf of a student.</summary>
        [HttpPost("clients/{clientId:guid}/meal-plans")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> CreateClientMealPlan(Guid clientId, [FromBody] MealPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.CreateClientMealPlanAsync(userId, clientId, request);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach submits / approves a meal plan for a student.</summary>
        [HttpPost("clients/{clientId:guid}/meal-plans/{planId:guid}/submit")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> SubmitClientMealPlan(Guid clientId, Guid planId, [FromBody] CoachSubmitMealPlanRequest? request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.SubmitClientMealPlanAsync(
                    userId,
                    clientId,
                    planId,
                    request
                );
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach deletes / deactivates a client meal plan.</summary>
        [HttpDelete("clients/{clientId:guid}/meal-plans/{planId:guid}")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> DeleteClientMealPlan(Guid clientId, Guid planId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                await _coachService.DeleteClientMealPlanAsync(userId, clientId, planId);
                return Ok(new { Message = "Meal plan deleted successfully." });
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("clients/{clientId:guid}/meal-plan")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientMealPlan(Guid clientId, [FromQuery] DateOnly date)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientMealPlanAsync(userId, clientId, date);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("clients/{clientId:guid}/suggestions")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientSuggestions(
            Guid clientId,
            [FromQuery] DateOnly? date = null,
            [FromQuery] int targetCalories = 0,
            [FromQuery] int? minCalories = null,
            [FromQuery] int? maxCalories = null,
            [FromQuery] decimal? minProteinG = null,
            [FromQuery] decimal? maxProteinG = null,
            [FromQuery] int top = 10)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientSuggestionsAsync(
                    userId,
                    clientId,
                    date,
                    targetCalories,
                    minCalories,
                    maxCalories,
                    minProteinG,
                    maxProteinG,
                    top
                );
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("clients/{clientId:guid}/gym-config")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientGymConfiguration(
            Guid clientId,
            [FromQuery] DateOnly? date = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientGymConfigurationAsync(
                    userId,
                    clientId,
                    date
                );
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("clients/{clientId:guid}/review-requests")]
        [Authorize]
        [Authorize(Policy = "CoachOnly")]
        public async Task<IActionResult> GetClientReviewRequests(Guid clientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GetClientReviewRequestsAsync(userId, clientId);
                return Ok(result);
            }
            catch (UnauthorizedAccessException ex)
            {
                return StatusCode(403, new { Message = ex.Message });
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
