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
    [Route("api/PremiumPrograms")]
    public class PremiumProgramsController : ControllerBase
    {
        private readonly IPremiumProgramService _premiumProgramService;

        public PremiumProgramsController(IPremiumProgramService premiumProgramService)
        {
            _premiumProgramService = premiumProgramService;
        }

        /// <summary>Get list of active Premium programs.</summary>
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetActivePrograms()
        {
            try
            {
                var result = await _premiumProgramService.GetActiveProgramsAsync();
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get detailed information of a Premium program package.</summary>
        [HttpGet("{id:guid}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetProgramById(Guid id)
        {
            try
            {
                var result = await _premiumProgramService.GetProgramByIdAsync(id);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Create purchase request for Premium program via SePay QR payment gateway.</summary>
        [HttpPost("{id:guid}/checkout")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> CheckoutProgram(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.PurchaseProgramAsync(userId, id);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Activate program after successful payment.</summary>
        [HttpPost("{id:guid}/activate")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> ActivateProgram(Guid id, [FromBody] ProgramActivationRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.ActivateProgramAsync(userId, id, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get current user's active Premium program.</summary>
        [HttpGet("my-active")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyActiveProgram()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.GetMyActiveProgramAsync(userId);
                if (result == null) return NotFound(new { Message = "You do not have any active Premium programs." });
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get user subscription history.</summary>
        [HttpGet("my-programs")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyPrograms()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.GetMyProgramsAsync(userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get weekly milestones of active Premium program.</summary>
        [HttpGet("my-active/milestones")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyActiveMilestones()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.GetMyActiveMilestonesAsync(userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Check-in weight and body fat metrics for current week.</summary>
        [HttpPost("my-active/milestones/{weekNumber:int}/checkin")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> CheckInWeek(int weekNumber, [FromBody] ProgramCheckInRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.CheckInWeekAsync(userId, weekNumber, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get user weight/body fat change trend in program.</summary>
        [HttpGet("my-active/progress-trend")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyActiveProgressTrend()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.GetMyActiveProgressTrendAsync(userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Request completion and graduation after final week.</summary>
        [HttpPost("my-active/graduate")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GraduateActiveProgram()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.GraduateActiveProgramAsync(userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Get detailed journey summary report after graduation (or ongoing progress).</summary>
        [HttpGet("my-active/wrap-up-report")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyActiveProgramReport()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var active = await _premiumProgramService.GetMyActiveProgramAsync(userId);
                if (active == null) return BadRequest(new { Message = "You do not have an active Premium program to get report from." });
                var result = await _premiumProgramService.GetMyProgramReportAsync(userId, active.Id);
                return Ok(result);
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
