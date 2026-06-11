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
    // [Authorize(Policy = "UserOnly")]
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
        /// Blocks and polls the AI microservice until the analysis is finished,
        /// then returns the full nutrition details and suggested recipes,
        /// including safety evaluations based on user's allergies.
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
                // Fallback to the default Demo user ID when unauthenticated for testing purposes
                userId = Guid.Parse("70000000-0000-0000-0000-000000000001");
            }

            try
            {
                using var stream = image.OpenReadStream();
                var result = await _cvService.AnalyzeImageAsync(userId, stream, image.FileName, image.ContentType);
                return Ok(result);
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return StatusCode(StatusCodes.Status502BadGateway, new { Message = ex.Message });
            }
            catch (TimeoutException ex)
            {
                return StatusCode(StatusCodes.Status504GatewayTimeout, new { Message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new { Message = ex.Message });
            }
        }
    }
}
