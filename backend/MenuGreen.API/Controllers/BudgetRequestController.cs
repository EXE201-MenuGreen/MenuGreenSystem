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
    /// Controller quản lý Yêu cầu Ngân sách (Budget Request) của người dùng.
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
        /// Lấy thông tin yêu cầu ngân sách đang hoạt động (gần nhất) của user hiện tại.
        /// </summary>
        [HttpGet("me")]
        public async Task<IActionResult> GetActive()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetActiveBudgetAsync(userId);
            if (result == null) return NotFound(new { Message = "Không tìm thấy cấu hình ngân sách nào." });
            return Ok(result);
        }

        /// <summary>
        /// Thiết lập ngân sách ăn uống mong muốn và giới hạn thời gian nấu ăn.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] BudgetRequestUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateAsync(userId, request));
        }

        /// <summary>
        /// Cập nhật thông tin ngân sách hoặc giới hạn thời gian nấu ăn theo Id.
        /// </summary>
        [HttpPut("{id:guid}")]
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
        /// Xóa cấu hình ngân sách đã thiết lập.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeleteAsync(userId, id);
                return Ok(new { Message = "Xóa cấu hình ngân sách thành công." });
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
