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
    /// Controller quản lý việc Gợi ý và Áp dụng nguyên liệu thay thế (Ingredient Substitution).
    /// </summary>
    [ApiController]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class IngredientSubstitutionController : ControllerBase
    {
        private readonly IIngredientSubstitutionService _service;

        public IngredientSubstitutionController(IIngredientSubstitutionService service)
        {
            _service = service;
        }

        /// <summary>
        /// Tìm kiếm danh sách các nguyên liệu thay thế phù hợp cho một nguyên liệu cụ thể.
        /// </summary>
        /// <param name="id">Mã nguyên liệu gốc</param>
        /// <param name="reason">Lý do thay thế (allergy, not_available, expensive)</param>
        /// <param name="maxPrice">Giá tiền trần tối đa mong muốn cho sản phẩm thay thế</param>
        /// <param name="macroMatch">So khớp thành phần Calo/Macro tương đồng</param>
        [HttpGet("api/Ingredient/{id:guid}/substitutes")]
        public async Task<IActionResult> GetSubstitutes(
            Guid id, [FromQuery] string reason = "not_available", [FromQuery] int? maxPrice = null, [FromQuery] bool macroMatch = false)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                var result = await _service.GetSubstitutesAsync(userId, id, reason, maxPrice, macroMatch);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Gợi ý nguyên liệu thay thế hàng loạt từ danh sách đầu vào phục vụ đi chợ hoặc chuẩn bị giỏ hàng.
        /// </summary>
        [HttpPost("api/Ingredient/substitutes/batch")]
        public async Task<IActionResult> GetBatchSubstitutes([FromBody] BatchSubstitutionRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetBatchSubstitutesAsync(userId, request));
        }

        /// <summary>
        /// Gợi ý nguyên liệu thay thế phù hợp trong ngữ cảnh ẩm thực của một công thức cụ thể kèm theo khối lượng cần dùng tương đương.
        /// </summary>
        [HttpGet("api/Recipe/{recipeId:guid}/substitute-ingredient/{ingredientId:guid}")]
        public async Task<IActionResult> GetRecipeIngredientSubstitutes(Guid recipeId, Guid ingredientId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetRecipeIngredientSubstitutesAsync(userId, recipeId, ingredientId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Tìm các công thức nấu ăn tương đồng và an toàn để thay thế cho công thức bị dính chất gây dị ứng.
        /// </summary>
        [HttpGet("api/Recipe/{recipeId:guid}/safe-alternatives")]
        public async Task<IActionResult> GetSafeRecipeAlternatives(Guid recipeId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.GetSafeRecipeAlternativesAsync(userId, recipeId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Áp dụng thay thế nguyên liệu trong một món ăn/công thức cụ thể đã lên kế hoạch và cập nhật calo.
        /// </summary>
        [HttpPost("api/MealPlan/{planId:guid}/items/{itemId:guid}/substitute-ingredient")]
        public async Task<IActionResult> ApplyMealPlanSubstitution(
            Guid planId, Guid itemId, [FromBody] IngredientSubstitutionApplyRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.ApplyMealPlanSubstitutionAsync(userId, planId, itemId, request);
                return Ok(new { Message = "Thay thế nguyên liệu trong kế hoạch thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Ghi nhận thay thế nguyên liệu trực tiếp khi người dùng đang nấu ăn thực tế vào nhật ký ăn uống.
        /// </summary>
        [HttpPost("api/NutritionTracking/meal-logs/{mealLogId:guid}/substitute-ingredient")]
        public async Task<IActionResult> ApplyMealLogSubstitution(
            Guid mealLogId, [FromBody] IngredientSubstitutionApplyRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.ApplyMealLogSubstitutionAsync(userId, mealLogId, request);
                return Ok(new { Message = "Ghi nhận thay thế nguyên liệu thực tế thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Lấy danh sách các cặp nguyên liệu thay thế ưa thích mặc định của người dùng hiện tại.
        /// </summary>
        [HttpGet("api/Ingredient/preferences/substitutes")]
        public async Task<IActionResult> GetPersonalPreferences()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetPersonalPreferencesAsync(userId));
        }

        /// <summary>
        /// Thiết lập cấu hình mặc định tự động thay thế nguyên liệu gốc bằng nguyên liệu thay thế.
        /// </summary>
        [HttpPost("api/Ingredient/preferences/substitutes")]
        public async Task<IActionResult> CreatePersonalPreference([FromBody] UserSubstitutePreferenceUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                return Ok(await _service.CreatePersonalPreferenceAsync(userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Xóa thiết lập tự động thay thế nguyên liệu mặc định.
        /// </summary>
        [HttpDelete("api/Ingredient/preferences/substitutes/{id:guid}")]
        public async Task<IActionResult> DeletePersonalPreference(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            try
            {
                await _service.DeletePersonalPreferenceAsync(userId, id);
                return Ok(new { Message = "Xóa cấu hình thành công." });
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
