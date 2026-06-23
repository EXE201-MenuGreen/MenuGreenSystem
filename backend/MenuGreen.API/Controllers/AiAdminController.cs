using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "AdminOnly")]
    public class AiAdminController : ControllerBase
    {
        private readonly INutritionAssistantService _nutritionAssistantService;

        public AiAdminController(INutritionAssistantService nutritionAssistantService)
        {
            _nutritionAssistantService = nutritionAssistantService;
        }

        [HttpGet("overview")]
        public async Task<IActionResult> GetOverview([FromQuery] int recentTake = 10)
        {
            var result = await _nutritionAssistantService.GetAdminOverviewAsync(recentTake);
            return Ok(result);
        }

        [HttpGet("health")]
        public async Task<IActionResult> GetHealth()
        {
            var result = await _nutritionAssistantService.GetBridgeHealthAsync();
            return Ok(result);
        }

        [HttpGet("debug/db")]
        public async Task<IActionResult> GetWorkerDebugDb([FromQuery] string? userId = null)
        {
            var result = await _nutritionAssistantService.GetWorkerDebugDbAsync(userId);
            return Ok(result);
        }

        [HttpGet("debug/postgres")]
        public async Task<IActionResult> GetWorkerDebugPostgres([FromQuery] string? userId = null)
        {
            var result = await _nutritionAssistantService.GetWorkerDebugPostgresAsync(userId);
            return Ok(result);
        }

        [HttpPost("crawler/normalize")]
        public async Task<IActionResult> NormalizeCrawlerData([FromBody] AiWorkerCrawlerNormalizeRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _nutritionAssistantService.NormalizeCrawlerDataAsync(request);
            return Ok(result);
        }

        [HttpPost("crawler/ingest")]
        public async Task<IActionResult> IngestCrawlerData([FromBody] AiWorkerCrawlerIngestRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _nutritionAssistantService.IngestCrawlerDataAsync(request);
            return Ok(result);
        }

        [HttpPost("training-samples")]
        public async Task<IActionResult> CreateTrainingSample([FromBody] AiWorkerCreateTrainingSampleRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _nutritionAssistantService.CreateTrainingSampleAsync(request);
            return StatusCode(201, result);
        }

        [HttpGet("training-samples")]
        public async Task<IActionResult> ListTrainingSamples([FromQuery] string? status = null, [FromQuery] int limit = 50)
        {
            var result = await _nutritionAssistantService.ListTrainingSamplesAsync(status, limit);
            return Ok(result);
        }

        [HttpPatch("training-samples/{sampleId}/review")]
        public async Task<IActionResult> ReviewTrainingSample(
            string sampleId,
            [FromBody] AiWorkerReviewTrainingSampleRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _nutritionAssistantService.ReviewTrainingSampleAsync(sampleId, request);
            return Ok(result);
        }

        [HttpPost("feedback/{feedbackId}/to-training-sample")]
        public async Task<IActionResult> CreateTrainingSampleFromFeedback(
            string feedbackId,
            [FromBody] AiWorkerCreateSampleFromFeedbackRequest request)
        {
            var result = await _nutritionAssistantService.CreateTrainingSampleFromFeedbackAsync(feedbackId, request);
            return StatusCode(201, result);
        }

        [HttpPost("curation/nightly")]
        public async Task<IActionResult> RunNightlyCuration([FromQuery] int limit = 200)
        {
            var result = await _nutritionAssistantService.RunNightlyCurationAsync(limit);
            return Ok(result);
        }
    }
}
