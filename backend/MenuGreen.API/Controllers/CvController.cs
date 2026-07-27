using System;
using System.IO;
using System.Linq;
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
        private const long MaxImageBytes = 10 * 1024 * 1024;

        private static readonly string[] AllowedContentTypes =
        [
            "image/jpeg",
            "image/jpg",
            "image/png",
            "image/webp",
        ];

        private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp"];

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
        [RequestSizeLimit(11 * 1024 * 1024)]
        [RequestFormLimits(MultipartBodyLengthLimit = 11 * 1024 * 1024)]
        public async Task<IActionResult> Analyze(IFormFile image)
        {
            if (image == null || image.Length == 0)
            {
                return BadRequest(new { Message = "Image file is required." });
            }

            if (image.Length > MaxImageBytes)
            {
                return StatusCode(
                    StatusCodes.Status413PayloadTooLarge,
                    new { Message = "Image cannot exceed 10 MB." }
                );
            }

            var safeFileName = Path.GetFileName(image.FileName);
            var extension = Path.GetExtension(safeFileName);
            var contentType = image.ContentType.Split(';', 2)[0].Trim().ToLowerInvariant();

            if (
                string.IsNullOrWhiteSpace(safeFileName)
                || !AllowedExtensions.Contains(extension, StringComparer.OrdinalIgnoreCase)
                || !AllowedContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase)
            )
            {
                return BadRequest(new { Message = "Only JPEG, PNG, and WebP images are supported." });
            }

            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId))
            {
                return Unauthorized(new { Message = "Invalid or missing user identity in token." });
            }

            using var stream = image.OpenReadStream();
            var signature = new byte[12];
            var signatureLength = await stream.ReadAsync(
                signature.AsMemory(0, signature.Length),
                HttpContext.RequestAborted
            );
            stream.Position = 0;

            if (!HasValidImageSignature(signature.AsSpan(0, signatureLength), contentType))
            {
                return BadRequest(new { Message = "The uploaded file is not a valid image." });
            }

            var result = await _cvService.AnalyzeImageAsync(
                userId,
                stream,
                safeFileName,
                contentType
            );
            return Ok(result);
        }

        private static bool HasValidImageSignature(ReadOnlySpan<byte> header, string contentType)
        {
            return contentType switch
            {
                "image/jpeg" or "image/jpg" =>
                    header.Length >= 3
                    && header[0] == 0xFF
                    && header[1] == 0xD8
                    && header[2] == 0xFF,
                "image/png" =>
                    header.Length >= 8
                    && header[..8].SequenceEqual(
                        new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }
                    ),
                "image/webp" =>
                    header.Length >= 12
                    && header[..4].SequenceEqual("RIFF"u8)
                    && header.Slice(8, 4).SequenceEqual("WEBP"u8),
                _ => false,
            };
        }
    }
}
