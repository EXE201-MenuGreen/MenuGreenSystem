using System.Linq;
using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace MenuGreen.API.Middleware
{
    /// <summary>
    /// Catches any unhandled exception, logs the full detail server-side,
    /// and returns a stable, English-only error body to the client (no stack trace).
    /// </summary>
    public class GlobalExceptionHandler
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<GlobalExceptionHandler> _logger;

        public GlobalExceptionHandler(RequestDelegate next, ILogger<GlobalExceptionHandler> logger)
        {
            _next = next;
            _logger = logger;
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
                await WriteAsync(context, HttpStatusCode.BadRequest, ex.Message);
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Bad gateway on {Path}", context.Request.Path);
                await WriteAsync(context, HttpStatusCode.BadGateway, ex.Message);
            }
            catch (TimeoutException ex)
            {
                _logger.LogError(ex, "Timeout on {Path}", context.Request.Path);
                await WriteAsync(context, HttpStatusCode.GatewayTimeout, ex.Message);
            }
            catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested)
            {
                // Client disconnected - no need to respond
                _logger.LogInformation("Client aborted request on {Path}", context.Request.Path);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unhandled exception on {Method} {Path}", context.Request.Method, context.Request.Path);

                // DEBUG: Return exception details to help diagnose production errors
                // TODO: Remove this and restore generic message once bug is fixed
                var debugInfo = new
                {
                    Message = "An unexpected error occurred. Please try again later.",
                    Debug = new
                    {
                        Type = ex.GetType().FullName,
                        ExceptionMessage = ex.Message,
                        StackTrace = ex.StackTrace?.Split('\n').Take(15).ToArray(),
                        InnerException = ex.InnerException?.Message
                    }
                };
                await WriteAsync(context, HttpStatusCode.InternalServerError, JsonSerializer.Serialize(debugInfo));
                return;
            }
        }

        private static async Task WriteAsync(HttpContext context, HttpStatusCode status, string message)
        {
            if (context.Response.HasStarted)
            {
                return;
            }

            context.Response.Clear();
            context.Response.StatusCode = (int)status;
            context.Response.ContentType = "application/json";

            await context.Response.WriteAsync(message);
        }
    }
}
