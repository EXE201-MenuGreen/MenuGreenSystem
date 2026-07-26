using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using MenuGreen.BusinessLogicLayer;
using MenuGreen.DataAccessLayer;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Prometheus;

// Enable legacy timestamp behavior in Npgsql to allow writing Unspecified/Local/Utc DateTimes to timestamptz columns
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

// Render (và nhiều PaaS) inject PORT; ghi đè ASPNETCORE_URLS sai định dạng trên dashboard.
var renderPort = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrWhiteSpace(renderPort))
{
    Environment.SetEnvironmentVariable("ASPNETCORE_URLS", $"http://0.0.0.0:{renderPort}");
}

var builder = WebApplication.CreateBuilder(args);

// Windows Event Log requires elevated permissions on some development machines.
// Keep local logging on console/debug so a denied Event Log write cannot stop API startup.
if (builder.Environment.IsDevelopment())
{
    builder.Logging.ClearProviders();
    builder.Logging.AddConsole();
    builder.Logging.AddDebug();
}

var firebaseCredentialPath = builder.Configuration["Firebase:CredentialPath"];
if (!string.IsNullOrWhiteSpace(firebaseCredentialPath))
{
    var fullPath = Path.IsPathRooted(firebaseCredentialPath)
        ? firebaseCredentialPath
        : Path.Combine(builder.Environment.ContentRootPath, firebaseCredentialPath);
    if (File.Exists(fullPath) && FirebaseApp.DefaultInstance == null)
    {
        FirebaseApp.Create(new AppOptions { Credential = GoogleCredential.FromFile(fullPath) });
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
builder.Services.AddScoped<
    MenuGreen.BusinessLogicLayer.Interfaces.INotificationHubService,
    MenuGreen.API.Hubs.NotificationHubService
>();

builder
    .Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System
            .Text
            .Json
            .JsonNamingPolicy
            .CamelCase;
        options.JsonSerializerOptions.Converters.Add(new DateOnlyConverter());
        options.JsonSerializerOptions.Converters.Add(new TimeOnlyConverter());
    });
builder.Services.AddEndpointsApiExplorer();

// Configure authorization policies for role-based and entitlement-based access control.
builder.Services.AddScoped<
    Microsoft.AspNetCore.Authorization.IAuthorizationHandler,
    MenuGreen.API.Authorization.EntitlementHandler
>();

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy(
        "UserOnly",
        policy => policy.RequireRole("Admin", "User", "Free", "Casual", "Gymer", "Office", "Coach")
    );
    options.AddPolicy("CoachOnly", policy => policy.RequireRole("Coach", "Admin"));
    options.AddPolicy(
        "FreeFeatures",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("free_features")
            )
    );
    options.AddPolicy(
        "CasualFeatures",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("casual_features")
            )
    );
    options.AddPolicy(
        "OfficeFeatures",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("office_features")
            )
    );
    options.AddPolicy(
        "AiFeatures",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("ai_features")
            )
    );
    options.AddPolicy(
        "GymerOnly",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("gym_features")
            )
    );
    options.AddPolicy(
        "CoachAccessOnly",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("coach_access")
            )
    );
    options.AddPolicy(
        "OfficeOnly",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("office_features")
            )
    );
    options.AddPolicy(
        "CasualOnly",
        policy =>
            policy.Requirements.Add(
                new MenuGreen.API.Authorization.EntitlementRequirement("casual_features")
            )
    );
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
    "http://localhost:3001",
};

// Get origins from config/env, or use defaults
var configuredOrigins =
    (
        builder.Configuration["AllowedOrigins"]
        ?? Environment.GetEnvironmentVariable("ALLOWED_ORIGINS")
    )?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? Array.Empty<string>();

// Always merge: default origins + env-configured origins
// This guarantees admin.menugreen.food is allowed regardless of env config
var allowedOrigins = defaultOrigins.Concat(configuredOrigins).Distinct().ToArray();

// If wildcard is configured, keep all origins allowed
var allowAnyOrigin = allowedOrigins.Contains("*");

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        corsPolicyName,
        policy =>
        {
            if (isDevelopment || allowAnyOrigin)
            {
                policy
                    .SetIsOriginAllowed(origin => true)
                    .AllowAnyMethod()
                    .AllowAnyHeader()
                    .AllowCredentials();
            }
            else
            {
                policy
                    .WithOrigins(allowedOrigins)
                    .AllowAnyMethod()
                    .AllowAnyHeader()
                    .AllowCredentials();
            }
        }
    );
});

// 1. Configure Swagger to show Authorize button (Enter Token)
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MenuGreen API", Version = "v1" });
    c.AddSecurityDefinition(
        "Bearer",
        new OpenApiSecurityScheme
        {
            Description = "Paste the Token here (without the 'Bearer ' prefix).",
            Name = "Authorization",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.Http,
            Scheme = "Bearer",
            BearerFormat = "JWT",
        }
    );
    c.AddSecurityRequirement(
        new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer",
                    },
                },
                new string[] { }
            },
        }
    );
});

// 2. Configure JWT Authentication
var secretKey = builder.Configuration["JwtSettings:SecretKey"];
if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");
}
var key = Encoding.ASCII.GetBytes(secretKey);

builder
    .Services.AddAuthentication(options =>
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
                if (
                    !string.IsNullOrEmpty(accessToken)
                    && path.StartsWithSegments("/notificationHub")
                )
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            },
        };
    });

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = Microsoft.AspNetCore.Http.StatusCodes.Status429TooManyRequests;

    // 1. Global Limiter: 100 requests per 1 minute per IP
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
        return RateLimitPartition.GetFixedWindowLimiter(
            ipAddress,
            _ => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }
        );
    });

    // 2. AiPolicy: 5 requests per 1 minute per User (fallback to IP if anonymous)
    options.AddPolicy(
        "AiPolicy",
        httpContext =>
        {
            var identity =
                httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                ?? httpContext.Connection.RemoteIpAddress?.ToString()
                ?? "unknown-user";
            return RateLimitPartition.GetFixedWindowLimiter(
                identity,
                _ => new FixedWindowRateLimiterOptions
                {
                    AutoReplenishment = true,
                    PermitLimit = 5,
                    Window = TimeSpan.FromMinutes(1),
                    QueueLimit = 0,
                }
            );
        }
    );

    // 3. AuthPolicy: 5 requests per 2 minutes per IP
    options.AddPolicy(
        "AuthPolicy",
        httpContext =>
        {
            var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
            return RateLimitPartition.GetFixedWindowLimiter(
                ipAddress,
                _ => new FixedWindowRateLimiterOptions
                {
                    AutoReplenishment = true,
                    PermitLimit = 5,
                    Window = TimeSpan.FromMinutes(2),
                    QueueLimit = 0,
                }
            );
        }
    );

    // 4. OtpPolicy: 2 requests per 1 minute per IP
    options.AddPolicy(
        "OtpPolicy",
        httpContext =>
        {
            var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
            return RateLimitPartition.GetFixedWindowLimiter(
                ipAddress,
                _ => new FixedWindowRateLimiterOptions
                {
                    AutoReplenishment = true,
                    PermitLimit = 2,
                    Window = TimeSpan.FromMinutes(1),
                    QueueLimit = 0,
                }
            );
        }
    );
});

// Health Checks
// var pgConnection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
//     ?? Environment.GetEnvironmentVariable("DATABASE_URL");

// if (string.IsNullOrEmpty(pgConnection))
// {
//     throw new InvalidOperationException("ConnectionStrings__DefaultConnection environment variable is not configured.");
// }

// Convert URI format to Npgsql keyword format if needed
var pgConnectionResolved = ConnectionStringHelper.ResolvePostgresConnectionString(
    builder.Configuration
);

var healthCheckRedisConnection = Environment.GetEnvironmentVariable("REDIS_URL");

builder
    .Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "ready" })
    .AddNpgSql(pgConnectionResolved, name: "postgresql", tags: new[] { "db", "ready" });

if (!string.IsNullOrWhiteSpace(healthCheckRedisConnection))
{
    builder
        .Services.AddHealthChecks()
        .AddRedis(healthCheckRedisConnection, name: "redis", tags: new[] { "cache", "ready" });
}

var app = builder.Build();

// Global exception handler - must be first in pipeline
app.UseMiddleware<MenuGreen.API.Middleware.GlobalExceptionHandler>();

// Auto-apply EF Core migrations on startup (only in non-Development environments)
if (!app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db =
        scope.ServiceProvider.GetRequiredService<MenuGreen.DataAccessLayer.Context.ApplicationDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

    // -------------------------------------------------------------------------
    // Diagnostics: identify the running image so production issues can be
    // correlated with the exact commit / DLL build that produced them.
    // -------------------------------------------------------------------------
    var gitSha = Environment.GetEnvironmentVariable("GIT_SHA") ?? "<unknown>";
    var dllVersion =
        typeof(MenuGreen.DataAccessLayer.Context.ApplicationDbContext)
            .Assembly.GetCustomAttributes(
                typeof(System.Reflection.AssemblyFileVersionAttribute),
                false
            )
            .OfType<System.Reflection.AssemblyFileVersionAttribute>()
            .FirstOrDefault()
            ?.Version
        ?? "<unknown>";
    logger.LogInformation(
        "[MIGRATION] GitSHA={GitSha} DataAccessLayerDllFileVersion={DllVersion}",
        gitSha,
        dllVersion
    );

    // -------------------------------------------------------------------------
    // List pending/applied migrations BEFORE applying (for diagnostics).
    // -------------------------------------------------------------------------
    List<string> applied = new();
    List<string> pending = new();
    try
    {
        applied = db.Database.GetAppliedMigrations().ToList();
        pending = db.Database.GetPendingMigrations().ToList();
        logger.LogInformation(
            "[MIGRATION] Applied ({Count}): [{List}]",
            applied.Count,
            string.Join(", ", applied)
        );
        logger.LogInformation(
            "[MIGRATION] Pending ({Count}): [{List}]",
            pending.Count,
            string.Join(", ", pending)
        );
    }
    catch (Exception ex)
    {
        logger.LogWarning(
            ex,
            "[MIGRATION] Could not enumerate migration status (DB may be unreachable). Will attempt Migrate() anyway."
        );
    }

    // -------------------------------------------------------------------------
    // Drift detection: if history contains a row that the running DLL does NOT
    // know about (e.g. previous image was rolled back), warn loudly. This is a
    // symptom of Use case B (history drift) and means auto-apply will throw.
    // -------------------------------------------------------------------------
    try
    {
        var known = db.Database.GetMigrations().ToHashSet();
        var unknownInHistory = applied.Where(id => !known.Contains(id)).ToList();
        if (unknownInHistory.Count > 0)
        {
            logger.LogWarning(
                "[MIGRATION] DRIFT DETECTED: {Count} migration(s) are recorded in __EFMigrationsHistory but are NOT present in the running DLL: [{List}]. "
                    + "Auto-apply will refuse to start. Rollback the image or remove the stale rows manually.",
                unknownInHistory.Count,
                string.Join(", ", unknownInHistory)
            );

            // AUTO-FIX: Remove unknown migrations from history since they don't exist in this DLL
            logger.LogInformation(
                "[MIGRATION] Auto-removing {Count} unknown migration(s) from __EFMigrationsHistory.",
                unknownInHistory.Count
            );
            foreach (var unknownId in unknownInHistory)
            {
                db.Database.ExecuteSqlRaw(
                    "DELETE FROM \"__EFMigrationsHistory\" WHERE \"MigrationId\" = {0}",
                    unknownId);
                logger.LogInformation("[MIGRATION] Removed: {MigrationId}", unknownId);
            }

            // Refresh applied/pending lists
            applied = db.Database.GetAppliedMigrations().ToList();
            pending = db.Database.GetPendingMigrations().ToList();
        }
    }
    catch (Exception ex)
    {
        logger.LogWarning(ex, "[MIGRATION] Could not run drift check.");
    }

    if (pending.Count > 0)
    {
        logger.LogInformation(
            "[MIGRATION] Will apply {Count} pending migration(s) now.",
            pending.Count
        );
    }

    // -------------------------------------------------------------------------
    // Apply migrations. If DB already has tables but empty __EFMigrationsHistory,
    // the deploy script seeds it with the baseline migration name, so EF skips
    // table creation and only applies any real delta migrations.
    // -------------------------------------------------------------------------
    try
    {
        logger.LogInformation("[MIGRATION] Applying database migrations...");
        db.Database.Migrate();
        logger.LogInformation("[MIGRATION] Database migrations applied successfully.");

        var appliedAfter = db.Database.GetAppliedMigrations().ToList();
        logger.LogInformation(
            "[MIGRATION] Post-apply Applied ({Count}): [{List}]",
            appliedAfter.Count,
            string.Join(", ", appliedAfter)
        );
    }
    catch (Exception ex)
    {
        logger.LogCritical(
            ex,
            "FATAL: Failed to apply database migrations. Application will NOT start."
        );
        throw;
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
app.MapHealthChecks(
    "/health",
    new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
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
                    duration = e.Value.Duration.TotalMilliseconds,
                }),
                totalDuration = report.TotalDuration.TotalMilliseconds,
            };
            await context.Response.WriteAsJsonAsync(result);
        },
    }
);

app.MapHealthChecks(
    "/health/ready",
    new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
    {
        Predicate = check => check.Tags.Contains("ready"),
        ResponseWriter = async (context, report) =>
        {
            context.Response.ContentType = "application/json";
            await context.Response.WriteAsJsonAsync(new { status = report.Status.ToString() });
        },
    }
);

app.MapHealthChecks(
    "/health/live",
    new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions { Predicate = _ => false }
);

app.Run();

public class DateOnlyConverter : JsonConverter<DateOnly>
{
    private const string DateFormat = "yyyy-MM-dd";

    public override DateOnly Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options
    )
    {
        if (reader.TokenType == JsonTokenType.Null)
            return default;

        var value = reader.GetString();
        if (string.IsNullOrEmpty(value))
            return default;

        if (DateOnly.TryParse(value, out var date))
            return date;

        if (
            DateOnly.TryParseExact(
                value,
                DateFormat,
                null,
                System.Globalization.DateTimeStyles.None,
                out var exactDate
            )
        )
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

public class TimeOnlyConverter : JsonConverter<TimeOnly>
{
    private const string TimeFormat = "HH:mm:ss";

    public override TimeOnly Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options
    )
    {
        if (reader.TokenType == JsonTokenType.Null)
            return default;

        var value = reader.GetString();
        if (string.IsNullOrEmpty(value))
            return default;

        if (TimeOnly.TryParse(value, out var time))
            return time;

        if (DateTime.TryParse(value, out var dt))
            return TimeOnly.FromDateTime(dt);

        throw new JsonException($"Unable to parse \"{value}\" as TimeOnly.");
    }

    public override void Write(Utf8JsonWriter writer, TimeOnly value, JsonSerializerOptions options)
    {
        writer.WriteStringValue(value.ToString(TimeFormat));
    }
}

public partial class Program { }
