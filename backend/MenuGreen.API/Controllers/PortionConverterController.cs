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
    /// <summary>
    /// Controller quản lý bộ quy đổi đơn vị Việt Nam dân dã sang hệ chuẩn gram/ml.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PortionConverterController : ControllerBase
    {
        private readonly IPortionConverterService _service;

        public PortionConverterController(IPortionConverterService service)
        {
            _service = service;
        }

        /// <summary>
        /// Lấy danh sách toàn bộ các đơn vị quy đổi dân dã mặc định của Việt Nam cùng mô tả.
        /// </summary>
        [HttpGet("units")]
        public async Task<IActionResult> GetDefaultUnits()
        {
            var result = await _service.GetDefaultUnitsAsync();
            return Ok(result);
        }

        /// <summary>
        /// Lấy danh sách đơn vị quy đổi dân dã được định nghĩa riêng cho một món ăn cụ thể.
        /// </summary>
        [HttpGet("units/food/{foodId:guid}")]
        public async Task<IActionResult> GetFoodUnits(Guid foodId)
        {
            var result = await _service.GetUnitsByFoodAsync(foodId);
            return Ok(result);
        }

        /// <summary>
        /// Thực hiện quy đổi số lượng đơn vị địa phương sang gram/ml và tính toán trước giá trị Calo/Macro tương ứng.
        /// </summary>
        [HttpPost("convert")]
        public async Task<IActionResult> Convert([FromBody] PortionConvertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            TryGetUserId(out var userId); // userId nullable

            try
            {
                var result = await _service.ConvertPortionAsync(request, userId == Guid.Empty ? null : userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách các đơn vị quy đổi cá nhân hóa do user tự tạo.
        /// </summary>
        [HttpGet("custom-units")]
        public async Task<IActionResult> GetCustomUnits()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetCustomUnitsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Đăng ký một đơn vị cá nhân mới (Ví dụ: "Tô sứ nhà" = 500g).
        /// </summary>
        [HttpPost("custom-units")]
        public async Task<IActionResult> CreateCustomUnit([FromBody] CustomUserPortionUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.CreateCustomUnitAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Cập nhật thông số trọng lượng của một đơn vị tùy chỉnh cá nhân.
        /// </summary>
        [HttpPut("custom-units/{id:guid}")]
        public async Task<IActionResult> UpdateCustomUnit(Guid id, [FromBody] CustomUserPortionUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.UpdateCustomUnitAsync(userId, id, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa một đơn vị tùy chỉnh cá nhân.
        /// </summary>
        [HttpDelete("custom-units/{id:guid}")]
        public async Task<IActionResult> DeleteCustomUnit(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.DeleteCustomUnitAsync(userId, id);
                return Ok(new { success = result, message = "Xóa đơn vị tùy chỉnh thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
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
