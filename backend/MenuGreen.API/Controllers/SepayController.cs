using System;
using System.IO;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/payments/sepay")]
    public class SepayController : ControllerBase
    {
        private readonly ISepayPaymentService _sepayPaymentService;

        public SepayController(ISepayPaymentService sepayPaymentService)
        {
            _sepayPaymentService = sepayPaymentService;
        }

        [HttpPost("create-renew-order")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> CreateRenewOrder([FromBody] CreateRenewSepayOrderRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _sepayPaymentService.CreateRenewOrderAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("create-order")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> CreateOrder([FromBody] CreateSepayOrderRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _sepayPaymentService.CreateOrderAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpGet("{paymentId:guid}")]
        [Authorize]
        [Authorize(Policy = "UserOnly")]
        public async Task<IActionResult> GetStatus(Guid paymentId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _sepayPaymentService.GetOrderStatusAsync(userId, paymentId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook()
        {
            try
            {
                var rawBody = await ReadRawBodyAsync();
                var signature = Request.Headers["X-SePay-Signature"].ToString();
                var timestamp = Request.Headers["X-SePay-Timestamp"].ToString();
                var authorization = Request.Headers.Authorization.ToString();

                await _sepayPaymentService.ProcessWebhookAsync(rawBody, signature, timestamp, authorization);

                // SePay only accepts exactly {"success": true} as success (see developer.sepay.vn).
                return Ok(new { success = true });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { success = false, message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        private async Task<string> ReadRawBodyAsync()
        {
            Request.EnableBuffering();
            Request.Body.Position = 0;

            using var reader = new StreamReader(Request.Body, Encoding.UTF8, detectEncodingFromByteOrderMarks: false, leaveOpen: true);
            var rawBody = await reader.ReadToEndAsync();
            Request.Body.Position = 0;
            return rawBody;
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
