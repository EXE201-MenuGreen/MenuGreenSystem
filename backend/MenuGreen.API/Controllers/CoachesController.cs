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

        /// <summary>Student revokes Coach health data access.</summary>
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
                return Forbid(ex.Message);
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
                return Forbid(ex.Message);
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
                return Forbid(ex.Message);
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
                return Forbid(ex.Message);
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
                    if (!isConnected) return Forbid("You do not have access to this student's feedback.");
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
                return Forbid(ex.Message);
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
                return Forbid(ex.Message);
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
