using System;
using System.Collections.Generic;
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
    /// Điều khiển các hoạt động liên quan đến quản lý hồ sơ dị ứng, đánh giá rủi ro dị ứng và gợi ý món ăn an toàn.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class AllergyController : ControllerBase
    {
        private readonly IAllergyService _service;
        private readonly IAllergenMatchingService _allergenMatching;

        public AllergyController(IAllergyService service, IAllergenMatchingService allergenMatching)
        {
            _service = service;
            _allergenMatching = allergenMatching;
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Lấy toàn bộ danh sách dị ứng của người dùng đang đăng nhập.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAllAsync(userId));
        }

        /// <summary>
        /// Thêm một mục dị ứng mới cho người dùng.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateAsync(userId, request));
        }

        /// <summary>
        /// Cập nhật thông tin của một mục dị ứng hiện có.
        /// </summary>
        [HttpPut("{allergyId:guid}")]
        public async Task<IActionResult> Update(Guid allergyId, [FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateAsync(userId, allergyId, request));
        }

        /// <summary>
        /// Xóa bỏ một mục dị ứng của người dùng.
        /// </summary>
        [HttpDelete("{allergyId:guid}")]
        public async Task<IActionResult> Delete(Guid allergyId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteAsync(userId, allergyId);
            return Ok();
        }

        /// <summary>
        /// Lấy hồ sơ dị ứng hiện tại của người dùng (tương tự danh sách dị ứng).
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAllAsync(userId));
        }

        /// <summary>
        /// Cập nhật hàng loạt hồ sơ chất dị ứng của người dùng (ví dụ khi hoàn tất Onboarding hoặc chỉnh sửa nhanh).
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] AllergyProfileUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request.Allergens));
        }

        /// <summary>
        /// Lấy danh mục tất cả các chất gây dị ứng được hệ thống MenuGreen hỗ trợ chuẩn hóa.
        /// </summary>
        [HttpGet("catalog")]
        public async Task<IActionResult> GetCatalog()
        {
            return Ok(await _service.GetCatalogAsync());
        }

        /// <summary>
        /// Đánh giá mức độ rủi ro dị ứng cho một món ăn cụ thể hoặc cho các nguyên liệu tự nhập.
        /// </summary>
        [HttpPost("evaluate")]
        public async Task<IActionResult> Evaluate([FromBody] AllergyEvaluateRequest request)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            if (request.FoodId.HasValue)
            {
                var result = await _allergenMatching.EvaluateFoodRiskAsync(request.FoodId.Value, userId);
                return Ok(result);
            }

            if (request.IngredientNamesVi != null)
            {
                var result = await _allergenMatching.EvaluateRecipeRiskAsync(null, request.IngredientNamesVi, userId);
                return Ok(result);
            }

            return BadRequest("Vui lòng cung cấp FoodId hoặc danh sách IngredientNamesVi.");
        }

        /// <summary>
        /// Đánh giá rủi ro dị ứng hàng loạt cho một danh sách các món ăn (sử dụng trên danh sách món ăn).
        /// </summary>
        [HttpPost("evaluate/batch")]
        public async Task<IActionResult> EvaluateBatch([FromBody] AllergyEvaluateBatchRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var result = await _allergenMatching.EvaluateFoodRiskBatchAsync(request.FoodIds, userId);
            return Ok(result);
        }

        /// <summary>
        /// Lấy nhãn rủi ro dị ứng (badge) cho một món cụ thể dựa trên mealId (chính là FoodId).
        /// </summary>
        [HttpGet("meal/{mealId:guid}/badge")]
        public async Task<IActionResult> GetMealBadge(Guid mealId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _allergenMatching.EvaluateFoodRiskAsync(mealId, userId);
            return Ok(result);
        }

        /// <summary>
        /// Gợi ý danh sách món ăn an toàn, loại bỏ hoàn toàn các món có nguy cơ dị ứng đối với người dùng.
        /// </summary>
        [HttpGet("recommendations")]
        public async Task<IActionResult> GetRecommendations()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetRecommendationsAsync(userId));
        }

        /// <summary>
        /// Làm mới và tính toán lại danh sách gợi ý món ăn an toàn cho người dùng.
        /// </summary>
        [HttpPost("recommendations/refresh")]
        public async Task<IActionResult> RefreshRecommendations()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            // Đối với gợi ý thời gian thực, refresh trực tiếp trả về danh sách gợi ý mới nhất
            return Ok(await _service.GetRecommendationsAsync(userId));
        }
    }
}
