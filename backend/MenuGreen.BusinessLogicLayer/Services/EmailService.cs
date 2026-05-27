using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.Extensions.Configuration;

namespace MenuGreen.BusinessLogicLayer.Services
{
    public class EmailService : IEmailService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public EmailService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _configuration = configuration;
        }

        public async Task SendVerificationEmailAsync(string toEmail, string otpCode)
        {
            var apiKey = _configuration["Resend:ApiKey"];
            if (string.IsNullOrEmpty(apiKey))
            {
                throw new Exception("Resend API Key is missing in configuration.");
            }

            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var payload = new
            {
                from = "MenuGreen <onboarding@resend.dev>",
                to = new[] { toEmail },
                subject = "MenuGreen - Mã OTP xác thực tài khoản",
                html = $@"
                    <div style='font-family: Arial, sans-serif; padding: 20px;'>
                        <h2 style='color: #2e7d32;'>Chào mừng bạn đến với MenuGreen! 🌱</h2>
                        <p>Cảm ơn bạn đã đăng ký tài khoản.</p>
                        <p>Vui lòng dùng mã OTP bên dưới để xác thực email của bạn:</p>
                        <div style='display:inline-block; padding:12px 20px; background:#f1f8e9; border:1px solid #c5e1a5; border-radius:8px; font-size:24px; font-weight:bold; letter-spacing:4px; color:#1b5e20;'>{otpCode}</div>
                        <p style='margin-top: 20px; font-size: 12px; color: #777;'>Mã này sẽ hết hạn sau 10 phút. Nếu bạn không yêu cầu, vui lòng bỏ qua email này.</p>
                    </div>"
            };

            await SendAsync(payload);
        }

        public async Task SendForgotPasswordEmailAsync(string toEmail, string otpCode)
        {
            var apiKey = _configuration["Resend:ApiKey"];
            if (string.IsNullOrEmpty(apiKey))
            {
                throw new Exception("Resend API Key is missing in configuration.");
            }

            _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);

            var payload = new
            {
                from = "MenuGreen <onboarding@resend.dev>",
                to = new[] { toEmail },
                subject = "MenuGreen - OTP đặt lại mật khẩu",
                html = $@"
                    <div style='font-family: Arial, sans-serif; padding: 20px;'>
                        <h2 style='color: #d32f2f;'>Yêu cầu đặt lại mật khẩu</h2>
                        <p>Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn.</p>
                        <p>Nhập mã OTP bên dưới để tiếp tục đặt lại mật khẩu:</p>
                        <div style='display:inline-block; padding:12px 20px; background:#ffebee; border:1px solid #ef9a9a; border-radius:8px; font-size:24px; font-weight:bold; letter-spacing:4px; color:#b71c1c;'>{otpCode}</div>
                        <p style='margin-top: 20px; font-size: 12px; color: #777;'>Mã này sẽ hết hạn sau 10 phút. Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
                    </div>"
            };

            await SendAsync(payload);
        }

        private async Task SendAsync(object payload)
        {
            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
            var response = await _httpClient.PostAsync("https://api.resend.com/emails", content);

            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync();
                throw new Exception($"Lỗi gửi email từ Resend: {error}");
            }
        }
    }
}
