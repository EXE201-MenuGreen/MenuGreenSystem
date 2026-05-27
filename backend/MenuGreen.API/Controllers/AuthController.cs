using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.RegisterAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var verified = await _authService.VerifyOtpAsync(request.Email, request.OtpCode);
                return verified
                    ? Ok(new { Message = "Xác thực OTP thành công." })
                    : BadRequest(new { Message = "OTP không hợp lệ hoặc đã hết hạn." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.ForgotPasswordAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.ResetPasswordAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.LoginAsync(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Unauthorized(new { Message = ex.Message });
            }
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                var response = await _authService.RefreshTokenAsync(request.RefreshToken);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Unauthorized(new { Message = ex.Message });
            }
        }

        [HttpPost("logout")]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                await _authService.LogoutAsync(request.RefreshToken);
                return Ok(new { Message = "Đăng xuất thành công." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
