using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "UserOnly")]
    [Microsoft.AspNetCore.RateLimiting.EnableRateLimiting("AiPolicy")]
    public class CvController : ControllerBase
    {
        private readonly ICvService _cvService;

        public CvController(ICvService cvService)
        {
            _cvService = cvService;
        }

        /// <summary>
        /// Analyzes a food image uploaded by the client.
        /// Sends the image to https://vision.menugreen.food, polls the job until completed,
        /// then returns the full nutrition details and suggested recipes,
        /// including safety evaluations based on user's allergies.
        /// Errors are translated to proper status codes by GlobalExceptionHandler.
        /// </summary>
        [HttpPost("analyze")]
        public async Task<IActionResult> Analyze(IFormFile image)
        {
            if (image == null || image.Length == 0)
            {
                return BadRequest(new { Message = "Image file is required." });
            }

            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId))
            {
                return Unauthorized(new { Message = "Invalid or missing user identity in token." });
            }

            using var stream = image.OpenReadStream();
            var result = await _cvService.AnalyzeImageAsync(userId, stream, image.FileName, image.ContentType);
            return Ok(result);
        }

        /// <summary>
        /// Analyzes a prepared meal image and returns inferred ingredients with
        /// estimated calories and macros.
        /// </summary>
        [HttpPost("analyze-prepared-meal")]
        public async Task<IActionResult> AnalyzePreparedMeal(IFormFile image)
        {
            if (image == null || image.Length == 0)
            {
                return BadRequest(new { Message = "Image file is required." });
            }

            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId))
            {
                return Unauthorized(new { Message = "Invalid or missing user identity in token." });
            }

            using var stream = image.OpenReadStream();
            var result = await _cvService.AnalyzePreparedMealAsync(
                userId, stream, image.FileName, image.ContentType);
            return Ok(result);
        }
    }
}
