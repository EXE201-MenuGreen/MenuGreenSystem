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

        /// <summary>Lấy danh sách các chương trình Premium đang hoạt động.</summary>
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

        /// <summary>Lấy thông tin chi tiết một gói chương trình Premium.</summary>
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

        /// <summary>Tạo yêu cầu mua chương trình Premium qua cổng thanh toán SePay QR.</summary>
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

        /// <summary>Kích hoạt bắt đầu chương trình sau khi đã thanh toán thành công.</summary>
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

        /// <summary>Lấy thông tin chương trình Premium hiện tại của user.</summary>
        [HttpGet("my-active")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyActiveProgram()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _premiumProgramService.GetMyActiveProgramAsync(userId);
                if (result == null) return NotFound(new { Message = "Bạn không có chương trình Premium nào đang hoạt động." });
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Lấy lịch sử các gói lộ trình đăng ký của user.</summary>
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

        /// <summary>Lấy các cột mốc tuần của gói Premium đang hoạt động.</summary>
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

        /// <summary>Thực hiện check-in nộp chỉ số cân nặng và mỡ của tuần hiện tại.</summary>
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

        /// <summary>Lấy xu hướng thay đổi cân nặng/mỡ cơ thể của user trong chương trình.</summary>
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

        /// <summary>Yêu cầu hoàn thành và tốt nghiệp chương trình sau khi hoàn thành tuần cuối.</summary>
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

        /// <summary>Lấy báo cáo tổng kết chi tiết lộ trình sau khi tốt nghiệp (hoặc tiến trình đang chạy).</summary>
        [HttpGet("my-active/wrap-up-report")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetMyActiveProgramReport()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var active = await _premiumProgramService.GetMyActiveProgramAsync(userId);
                if (active == null) return BadRequest(new { Message = "Bạn không có chương trình Premium nào đang hoạt động để lấy báo cáo." });
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
