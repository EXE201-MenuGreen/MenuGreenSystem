using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.API.Filters;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "UserOnly")]
    [CvExceptionFilter]
    public class CvController : ControllerBase
    {
        private readonly ICvService _cvService;

        public CvController(ICvService cvService)
        {
            _cvService = cvService;
        }

        /// <summary>
        /// Analyzes a food image uploaded by the client.
        /// Blocks and polls the AI microservice until the analysis is finished,
        /// then returns the full nutrition details and suggested recipes,
        /// including safety evaluations based on user's allergies.
        /// </summary>
        [HttpPost("analyze")]
        [EnableRateLimiting("CvScanPolicy")]
        public async Task<IActionResult> Analyze(IFormFile image)
        {
            if (image == null || image.Length == 0)
            {
                return BadRequest(new { Message = "Image file is required." });
            }

            if (!IsSupportedImageContentType(image.ContentType))
            {
                return BadRequest(
                    new { Message = "Only JPEG, PNG, and WEBP images are supported." }
                );
            }

            if (!TryGetUserId(out var userId))
            {
                return Unauthorized(new { Message = "A valid authenticated user is required." });
            }

            using var stream = image.OpenReadStream();
            var result = await _cvService.AnalyzeImageAsync(
                userId,
                stream,
                image.FileName,
                image.ContentType
            );
            return Ok(result);
        }

        [HttpPost("meal-log")]
        public async Task<IActionResult> CreateMealLogFromCvDish(
            [FromBody] CvMealLogCreateRequest request
        )
        {
            if (!TryGetUserId(out var userId))
            {
                return Unauthorized(new { Message = "A valid authenticated user is required." });
            }

            var result = await _cvService.CreateMealLogFromCvDishAsync(userId, request);
            return Ok(result);
        }

        private static bool IsSupportedImageContentType(string? contentType)
        {
            return string.Equals(contentType, "image/jpeg", StringComparison.OrdinalIgnoreCase)
                || string.Equals(contentType, "image/png", StringComparison.OrdinalIgnoreCase)
                || string.Equals(contentType, "image/webp", StringComparison.OrdinalIgnoreCase);
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
