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

        /// <summary>Lọc và tìm kiếm danh sách các huấn luyện viên/chuyên gia.</summary>
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

        /// <summary>Xem chi tiết hồ sơ một Coach.</summary>
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

        /// <summary>Đăng ký nâng cấp tài khoản của mình lên vai trò Coach chuyên gia.</summary>
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

        /// <summary>Học viên gửi yêu cầu kết nối với một Coach.</summary>
        [HttpPost("connect/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> ConnectCoach(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.ConnectCoachAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Yêu cầu kết nối đã được gửi đến Coach." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach phê duyệt hoặc từ chối yêu cầu kết nối của học viên.</summary>
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
                return Ok(new { Success = result, Message = request.Approve ? "Đã chấp nhận kết nối học viên." : "Đã từ chối kết nối học viên." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach lấy danh sách các học viên đang kết nối với mình.</summary>
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

        /// <summary>Học viên chủ động cấp quyền truy cập dữ liệu sức khỏe cho Coach.</summary>
        [HttpPost("grant-access/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GrantAccess(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.GrantAccessAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Đã cấp quyền truy cập dữ liệu cho Coach." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Học viên thu hồi quyền truy cập dữ liệu sức khỏe của Coach.</summary>
        [HttpPost("revoke-access/{coachId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> RevokeAccess(Guid coachId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _coachService.RevokeAccessAsync(userId, coachId);
                return Ok(new { Success = result, Message = "Đã thu hồi quyền truy cập dữ liệu của Coach." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach xem chi tiết chỉ số cơ thể, mục tiêu và dị ứng của học viên.</summary>
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

        /// <summary>Coach xem tổng hợp dinh dưỡng thực tế nạp vào của học viên.</summary>
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

        /// <summary>Coach xem xu hướng cân nặng thực tế của học viên.</summary>
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

        /// <summary>Coach gửi nhận xét, đánh giá cho học viên.</summary>
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

        /// <summary>Học viên (hoặc Coach) lấy danh sách nhận xét, phản hồi.</summary>
        [HttpGet("clients/{clientId:guid}/feedback")]
        [Authorize]
        public async Task<IActionResult> GetFeedbacks(Guid clientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                // Verify user is either the client himself or the coach who has connected access
                if (userId != clientId)
                {
                    // If not client, must be coach
                    var connection = (await _coachService.GetMyClientsAsync(userId));
                    bool isConnected = false;
                    foreach (var c in connection)
                    {
                        if (c.ClientId == clientId) isConnected = true;
                    }
                    if (!isConnected) return Forbid("Bạn không có quyền truy cập phản hồi của học viên này.");
                }

                var result = await _coachService.GetFeedbacksAsync(clientId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>Coach điều chỉnh/sửa đổi thực đơn kế hoạch ăn uống của học viên.</summary>
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

        /// <summary>Coach trực tiếp cập nhật mục tiêu Calo/Macros của học viên.</summary>
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
