using System;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller for comparing User Meal Plan and Actual Eating.
    /// </summary>
    [ApiController]
    [Route("api/Analytics/planned-vs-actual")]
    [Authorize]
    public class PlannedVsActualController : ControllerBase
    {
        private readonly IPlannedVsActualService _service;

        public PlannedVsActualController(IPlannedVsActualService service)
        {
            _service = service;
        }

        /// <summary>
        /// Compare planned vs actual Calo/Macro for a time period.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetSummary([FromQuery] DateOnly? from = null, [FromQuery] DateOnly? to = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var fromDate = from ?? today.AddDays(-6);
            var toDate = to ?? today;

            if (fromDate > toDate)
            {
                return BadRequest("Start date (from) cannot be greater than end date (to).");
            }

            var result = await _service.GetSummaryAsync(userId, fromDate, toDate);
            return Ok(result);
        }

        /// <summary>
        /// Calculate user meal plan adherence score (100-point scale).
        /// </summary>
        [HttpGet("adherence-score")]
        public async Task<IActionResult> GetAdherenceScore([FromQuery] DateOnly? from = null, [FromQuery] DateOnly? to = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var fromDate = from ?? today.AddDays(-6);
            var toDate = to ?? today;

            if (fromDate > toDate)
            {
                return BadRequest("Start date (from) cannot be greater than end date (to).");
            }

            var result = await _service.GetAdherenceScoreAsync(userId, fromDate, toDate);
            return Ok(result);
        }

        /// <summary>
        /// Analyze detailed causes of plan deviation (skipped meals, eating off-plan, food substitution, wrong portions).
        /// </summary>
        [HttpGet("drift-analysis")]
        public async Task<IActionResult> GetDriftAnalysis([FromQuery] DateOnly? from = null, [FromQuery] DateOnly? to = null)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var fromDate = from ?? today.AddDays(-6);
            var toDate = to ?? today;

            if (fromDate > toDate)
            {
                return BadRequest("Start date (from) cannot be greater than end date (to).");
            }

            var result = await _service.GetDriftAnalysisAsync(userId, fromDate, toDate);
            return Ok(result);
        }

        /// <summary>
        /// Provide corrective action suggestions based on deviation trends in the past 7 days.
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<IActionResult> GetRecommendations()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetRecommendationsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Run auto-redistribution algorithm for calorie/macro based on weight log and adherence progress.
        /// </summary>
        [HttpPost("recalibrate")]
        public async Task<IActionResult> Recalibrate()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.RecalibrateNutritionAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Export meal plan adherence progress report (JSON or HTML report).
        /// </summary>
        [HttpGet("monthly-report")]
        public async Task<IActionResult> GetMonthlyReport([FromQuery] int? month = null, [FromQuery] int? year = null, [FromQuery] string format = "json")
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var now = DateTime.UtcNow;
            var reportMonth = month ?? now.Month;
            var reportYear = year ?? now.Year;

            if (reportMonth < 1 || reportMonth > 12)
            {
                return BadRequest("Invalid month (must be between 1 and 12).");
            }

            if (reportYear < 2000 || reportYear > 2100)
            {
                return BadRequest("Invalid year.");
            }

            if (format.Trim().ToLower() == "html")
            {
                var html = await _service.GenerateMonthlyReportHtmlAsync(userId, reportMonth, reportYear);
                return Content(html, "text/html", Encoding.UTF8);
            }

            var fromDate = new DateOnly(reportYear, reportMonth, 1);
            var toDate = fromDate.AddMonths(1).AddDays(-1);
            if (toDate > DateOnly.FromDateTime(DateTime.UtcNow))
            {
                toDate = DateOnly.FromDateTime(DateTime.UtcNow);
            }

            var summary = await _service.GetSummaryAsync(userId, fromDate, toDate);
            var score = await _service.GetAdherenceScoreAsync(userId, fromDate, toDate);
            var drift = await _service.GetDriftAnalysisAsync(userId, fromDate, toDate);

            return Ok(new
            {
                Month = reportMonth,
                Year = reportYear,
                Summary = summary,
                AdherenceScore = score,
                DriftAnalysis = drift
            });
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
