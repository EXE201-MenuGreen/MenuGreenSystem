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
    /// Controller quản lý so sánh Kế hoạch ăn uống và Thực tế ăn uống của User.
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
        /// So sánh tổng Calo/Macro kế hoạch và thực tế theo khoảng thời gian.
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
                return BadRequest("Ngày bắt đầu (from) không được lớn hơn ngày kết thúc (to).");
            }

            var result = await _service.GetSummaryAsync(userId, fromDate, toDate);
            return Ok(result);
        }

        /// <summary>
        /// Tính toán điểm số bám sát kế hoạch ăn uống của user (thang điểm 100).
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
                return BadRequest("Ngày bắt đầu (from) không được lớn hơn ngày kết thúc (to).");
            }

            var result = await _service.GetAdherenceScoreAsync(userId, fromDate, toDate);
            return Ok(result);
        }

        /// <summary>
        /// Phân tích chi tiết các nguyên nhân gây lệch kế hoạch (bỏ bữa, ăn ngoài plan, thay món, sai định lượng).
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
                return BadRequest("Ngày bắt đầu (from) không được lớn hơn ngày kết thúc (to).");
            }

            var result = await _service.GetDriftAnalysisAsync(userId, fromDate, toDate);
            return Ok(result);
        }

        /// <summary>
        /// Đưa ra gợi ý hành động khắc phục dựa trên xu hướng lệch trong 7 ngày gần nhất.
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<IActionResult> GetRecommendations()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetRecommendationsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Chạy thuật toán tự động tái phân bổ lượng calo/macro dựa trên log cân nặng và tiến độ bám sát.
        /// </summary>
        [HttpPost("recalibrate")]
        public async Task<IActionResult> Recalibrate()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.RecalibrateNutritionAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Xuất báo cáo tiến độ và kết quả bám sát kế hoạch ăn uống (JSON hoặc HTML report).
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
                return BadRequest("Tháng không hợp lệ (phải từ 1 đến 12).");
            }

            if (reportYear < 2000 || reportYear > 2100)
            {
                return BadRequest("Năm không hợp lệ.");
            }

            if (format.Trim().ToLower() == "html")
            {
                var html = await _service.GenerateMonthlyReportHtmlAsync(userId, reportMonth, reportYear);
                return Content(html, "text/html", Encoding.UTF8);
            }

            // Mặc định trả về JSON tổng hợp báo cáo đầy đủ
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
