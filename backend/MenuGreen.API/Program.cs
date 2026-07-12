using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MenuGreen.DataAccessLayer;
using MenuGreen.BusinessLogicLayer;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Prometheus;

// Render (và nhiều PaaS) inject PORT; ghi đè ASPNETCORE_URLS sai định dạng trên dashboard.
var renderPort = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrWhiteSpace(renderPort))
{
    Environment.SetEnvironmentVariable("ASPNETCORE_URLS", $"http://0.0.0.0:{renderPort}");
}

var builder = WebApplication.CreateBuilder(args);

var firebaseCredentialPath = builder.Configuration["Firebase:CredentialPath"];
if (!string.IsNullOrWhiteSpace(firebaseCredentialPath))
{
    var fullPath = Path.IsPathRooted(firebaseCredentialPath)
        ? firebaseCredentialPath
        : Path.Combine(builder.Environment.ContentRootPath, firebaseCredentialPath);
    if (File.Exists(fullPath) && FirebaseApp.DefaultInstance == null)
    {
        FirebaseApp.Create(new AppOptions
        {
            Credential = GoogleCredential.FromFile(fullPath),
        });
    }
}

// Add services to the container.
builder.Services.AddDataAccessLayer(builder.Configuration);

var redisConnection =
    builder.Configuration["Redis:ConnectionString"]
    ?? Environment.GetEnvironmentVariable("REDIS_URL");

if (!string.IsNullOrWhiteSpace(redisConnection))
{
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = redisConnection;
        options.InstanceName = "MenuGreen:";
    });
}
else
{
    builder.Services.AddDistributedMemoryCache();
}

builder.Services.AddBusinessLogicLayer();

builder.Services.AddSignalR();
builder.Services.AddScoped<MenuGreen.BusinessLogicLayer.Interfaces.INotificationHubService, MenuGreen.API.Hubs.NotificationHubService>();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.Converters.Add(new DateOnlyConverter());
    });
builder.Services.AddEndpointsApiExplorer();

// Configure authorization policies for role-based access control.
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("UserOnly", policy => policy.RequireRole("User", "Admin", "Free", "Pro"));
    options.AddPolicy("CoachOnly", policy => policy.RequireRole("Coach", "Admin"));
});

// Configure CORS - Allow frontend domains
var isDevelopment = builder.Environment.IsDevelopment();
var corsPolicyName = isDevelopment ? "AllowAll" : "ProductionPolicy";

// Default allowed origins for production
var defaultOrigins = new[]
{
    "https://admin.menugreen.food",
    "https://www.menugreen.food",
    "https://menugreen.food",
    "https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app",
    "http://localhost:3000",
    "http://localhost:3001"
};

// Get origins from config/env, or use defaults
var configuredOrigins = (builder.Configuration["AllowedOrigins"]
    ?? Environment.GetEnvironmentVariable("ALLOWED_ORIGINS"))
    ?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? Array.Empty<string>();

// Always merge: default origins + env-configured origins
// This guarantees admin.menugreen.food is allowed regardless of env config
var allowedOrigins = defaultOrigins
    .Concat(configuredOrigins)
    .Distinct()
    .ToArray();

// If wildcard is configured, keep all origins allowed
var allowAnyOrigin = allowedOrigins.Contains("*");

builder.Services.AddCors(options =>
{
    options.AddPolicy(corsPolicyName, policy =>
    {
        if (isDevelopment || allowAnyOrigin)
        {
            policy.SetIsOriginAllowed(origin => true)
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        }
        else
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        }
    });
});

// 1. Configure Swagger to show Authorize button (Enter Token)
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MenuGreen API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Paste the Token here (without the 'Bearer ' prefix).",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

// 2. Configure JWT Authentication
var secretKey = builder.Configuration["JwtSettings:SecretKey"];
if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");
}
var key = Encoding.ASCII.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = !string.IsNullOrEmpty(builder.Configuration["JwtSettings:Issuer"]),
        ValidIssuer = builder.Configuration["JwtSettings:Issuer"],
        ValidateAudience = !string.IsNullOrEmpty(builder.Configuration["JwtSettings:Audience"]),
        ValidAudience = builder.Configuration["JwtSettings:Audience"],
    };
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/notificationHub"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = Microsoft.AspNetCore.Http.StatusCodes.Status429TooManyRequests;

    // 1. Global Limiter: 100 requests per 1 minute per IP
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
        return RateLimitPartition.GetFixedWindowLimiter(ipAddress, _ => new FixedWindowRateLimiterOptions
        {
            AutoReplenishment = true,
            PermitLimit = 100,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });

    // 2. AiPolicy: 5 requests per 1 minute per User (fallback to IP if anonymous)
    options.AddPolicy("AiPolicy", httpContext =>
    {
        var identity = httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                       ?? httpContext.Connection.RemoteIpAddress?.ToString()
                       ?? "unknown-user";
        return RateLimitPartition.GetFixedWindowLimiter(identity, _ => new FixedWindowRateLimiterOptions
        {
            AutoReplenishment = true,
            PermitLimit = 5,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });

    // 3. AuthPolicy: 5 requests per 2 minutes per IP
    options.AddPolicy("AuthPolicy", httpContext =>
    {
        var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
        return RateLimitPartition.GetFixedWindowLimiter(ipAddress, _ => new FixedWindowRateLimiterOptions
        {
            AutoReplenishment = true,
            PermitLimit = 5,
            Window = TimeSpan.FromMinutes(2),
            QueueLimit = 0
        });
    });

    // 4. OtpPolicy: 2 requests per 1 minute per IP
    options.AddPolicy("OtpPolicy", httpContext =>
    {
        var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
        return RateLimitPartition.GetFixedWindowLimiter(ipAddress, _ => new FixedWindowRateLimiterOptions
        {
            AutoReplenishment = true,
            PermitLimit = 2,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        });
    });
});

// Health Checks
// var pgConnection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
//     ?? Environment.GetEnvironmentVariable("DATABASE_URL");

// if (string.IsNullOrEmpty(pgConnection))
// {
//     throw new InvalidOperationException("ConnectionStrings__DefaultConnection environment variable is not configured.");
// }

// Convert URI format to Npgsql keyword format if needed
var pgConnectionResolved = ConnectionStringHelper.ResolvePostgresConnectionString(builder.Configuration);

var healthCheckRedisConnection = Environment.GetEnvironmentVariable("REDIS_URL");

builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "ready" })
    .AddNpgSql(pgConnectionResolved, name: "postgresql", tags: new[] { "db", "ready" });

if (!string.IsNullOrWhiteSpace(healthCheckRedisConnection))
{
    builder.Services.AddHealthChecks()
        .AddRedis(healthCheckRedisConnection, name: "redis", tags: new[] { "cache", "ready" });
}

var app = builder.Build();

// Global exception handler - must be first in pipeline
app.UseMiddleware<MenuGreen.API.Middleware.GlobalExceptionHandler>();

// Auto-apply EF Core migrations on startup (only in non-Development environments)
if (!app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<MenuGreen.DataAccessLayer.Context.ApplicationDbContext>();
    try
    {
        app.Logger.LogInformation("Applying database migrations...");
        db.Database.Migrate();
        app.Logger.LogInformation("Database migrations applied successfully.");
    }
    catch (Exception ex)
    {
        app.Logger.LogError(ex, "Failed to apply database migrations. Starting application anyway...");
    }
}

// Seed data: run backend/run_seed_data.ps1 after migrations.

// Configure the HTTP request pipeline.

app.UseSwagger();
app.UseSwaggerUI();

// Prometheus metrics endpoint
app.UseMetricServer(); // /metrics endpoint
app.UseHttpMetrics(); // Auto-instrument HTTP requests


// Enable CORS
app.UseCors(isDevelopment ? "AllowAll" : "ProductionPolicy");

// HTTPS redirection handled by reverse proxy (nginx in docker-compose)

if (!app.Environment.IsDevelopment())
{
    app.UseRateLimiter();
}
app.UseAuthentication(); // MUST BE BEFORE UseAuthorization
app.UseAuthorization();

app.MapControllers();
app.MapHub<MenuGreen.API.Hubs.NotificationHub>("/notificationHub");

// Health check endpoints
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => true,
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                duration = e.Value.Duration.TotalMilliseconds
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        };
        await context.Response.WriteAsJsonAsync(result);
    }
});

app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new { status = report.Status.ToString() });
    }
});

app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => false
});

app.Run();

public class DateOnlyConverter : JsonConverter<DateOnly>
{
    private const string DateFormat = "yyyy-MM-dd";

    public override DateOnly Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
            return default;

        var value = reader.GetString();
        if (string.IsNullOrEmpty(value))
            return default;

        if (DateOnly.TryParse(value, out var date))
            return date;

        if (DateOnly.TryParseExact(value, DateFormat, null, System.Globalization.DateTimeStyles.None, out var exactDate))
            return exactDate;

        if (DateTime.TryParse(value, out var dt))
            return DateOnly.FromDateTime(dt);

        throw new JsonException($"Unable to parse \"{value}\" as DateOnly.");
    }

    public override void Write(Utf8JsonWriter writer, DateOnly value, JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.ToString(DateFormat));
    }
}
