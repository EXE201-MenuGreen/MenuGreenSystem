using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace MenuGreen.API.Middleware
{
    /// <summary>
    /// Catches any unhandled exception, logs the full detail server-side,
    /// and returns a stable, English-only error body to the client (no stack trace).
    /// In Development, includes full exception detail for easier debugging.
    /// </summary>
    public class GlobalExceptionHandler
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionHandler> _logger;
        private readonly IHostEnvironment _env;

        public GlobalExceptionHandler(
            RequestDelegate next,
            ILogger<GlobalExceptionHandler> logger,
            IHostEnvironment env)
        {
            _next = next;
            _logger = logger;
            _env = env;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (ArgumentException ex)
            {
                _logger.LogWarning(ex, "Bad request on {Path}", context.Request.Path);
                await WriteAsync(context, HttpStatusCode.BadRequest, ex.Message, ex);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Bad gateway on {Path}", context.Request.Path);
                await WriteAsync(context, HttpStatusCode.BadGateway, ex.Message, ex);
            }
            catch (TimeoutException ex)
            {
                _logger.LogError(ex, "Timeout on {Path}", context.Request.Path);
                await WriteAsync(context, HttpStatusCode.GatewayTimeout, ex.Message, ex);
            }
            catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
            {
                // Client disconnected - no need to respond
                _logger.LogInformation("Client aborted request on {Path}", context.Request.Path);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled exception on {Method} {Path}", context.Request.Method, context.Request.Path);
                // Show full error details for diagnostics - backend team can switch off later
                // by setting "DetailedErrors": false in appsettings or via env var
                var showDetailedErrors = _env.IsDevelopment()
                    || string.Equals(Environment.GetEnvironmentVariable("SHOW_DETAILED_ERRORS"), "true", StringComparison.OrdinalIgnoreCase);
                var msg = showDetailedErrors
                    ? ex.Message
                    : "An unexpected error occurred. Please try again later.";
                await WriteAsync(context, HttpStatusCode.InternalServerError, msg, showDetailedErrors ? ex : null);
            }
        }

        private async Task WriteAsync(HttpContext context, HttpStatusCode status, string message, Exception? ex = null)
        {
            if (context.Response.HasStarted)
            {
                return;
            }

            context.Response.Clear();
            context.Response.StatusCode = (int)status;
            context.Response.ContentType = "application/json";

            var showDetailed = _env.IsDevelopment()
                || string.Equals(Environment.GetEnvironmentVariable("SHOW_DETAILED_ERRORS"), "true", StringComparison.OrdinalIgnoreCase);

            object body = showDetailed && ex != null
                ? new
                {
                    Message = message,
                    ExceptionType = ex.GetType().FullName,
                    StackTrace = ex.StackTrace?.Split('\n').Take(10).ToArray(),
                    InnerException = ex.InnerException?.Message
                }
                : (object)new { Message = message };

            var json = JsonSerializer.Serialize(body, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });
            await context.Response.WriteAsync(json);
        }
    }
}
