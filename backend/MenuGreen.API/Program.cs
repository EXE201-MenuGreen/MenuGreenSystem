using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using MenuGreen.API.Security;
using MenuGreen.BusinessLogicLayer;
using MenuGreen.DataAccessLayer;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.HttpOverrides;
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

const long DefaultRequestBodyBytes = 1 * 1024 * 1024;
const long MultipartRequestBodyBytes = 11 * 1024 * 1024;

builder.WebHost.ConfigureKestrel(options =>
{
    options.AddServerHeader = false;
    options.Limits.MaxRequestBodySize = DefaultRequestBodyBytes;
    options.Limits.MaxRequestBufferSize = DefaultRequestBodyBytes;
    options.Limits.MaxRequestHeaderCount = 100;
    options.Limits.MaxRequestHeadersTotalSize = 32 * 1024;
    options.Limits.MaxRequestLineSize = 8 * 1024;
    options.Limits.RequestHeadersTimeout = TimeSpan.FromSeconds(15);
    options.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(2);
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = MultipartRequestBodyBytes;
    options.ValueLengthLimit = 64 * 1024;
    options.KeyLengthLimit = 256;
    options.ValueCountLimit = 1_024;
    options.MultipartHeadersCountLimit = 32;
    options.MultipartHeadersLengthLimit = 16 * 1024;
});

// Windows Event Log requires elevated permissions on some development machines.
// Keep local logging on console/debug so a denied Event Log write cannot stop API startup.
if (builder.Environment.IsDevelopment())
{
    builder.Logging.ClearProviders();
    builder.Logging.AddConsole();
    builder.Logging.AddDebug();
}

// Goong requires its API key in the query string. Suppress informational HttpClient
// URL logging for that named client so the key cannot be copied into application logs.
builder.Logging.AddFilter("System.Net.Http.HttpClient.Goong", LogLevel.Warning);

var firebaseCredentialPath = builder.Configuration["Firebase:CredentialPath"];
if (!string.IsNullOrWhiteSpace(firebaseCredentialPath))
{
    var fullPath = Path.IsPathRooted(firebaseCredentialPath)
        ? firebaseCredentialPath
        : Path.Combine(builder.Environment.ContentRootPath, firebaseCredentialPath);
    if (File.Exists(fullPath) && FirebaseApp.DefaultInstance == null)
    {
        FirebaseApp.Create(
            new AppOptions
            {
                Credential = CredentialFactory
                    .FromFile<ServiceAccountCredential>(fullPath)
                    .ToGoogleCredential(),
            }
        );
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
builder.Services.AddScoped<InputSecurityFilter>();
builder.Services.AddHttpClient(
    "Goong",
    client =>
    {
        client.BaseAddress = new Uri("https://rsapi.goong.io/");
        client.Timeout = TimeSpan.FromSeconds(10);
    }
);

builder.Services.AddSignalR();
builder.Services.AddScoped<
    MenuGreen.BusinessLogicLayer.Interfaces.INotificationHubService,
    MenuGreen.API.Hubs.NotificationHubService
>();

builder
    .Services.AddControllers(options => options.Filters.Add<InputSecurityFilter>())
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System
            .Text
            .Json
            .JsonNamingPolicy
            .CamelCase;
        options.JsonSerializerOptions.MaxDepth = 32;
        options.JsonSerializerOptions.AllowTrailingCommas = false;
        options.JsonSerializerOptions.ReadCommentHandling = JsonCommentHandling.Disallow;
        options.JsonSerializerOptions.UnmappedMemberHandling = JsonUnmappedMemberHandling.Disallow;
        options.JsonSerializerOptions.Converters.Add(new DateOnlyConverter());
        options.JsonSerializerOptions.Converters.Add(new TimeOnlyConverter());
    });
builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context
            .ModelState.Where(entry => entry.Value?.Errors.Count > 0)
            .ToDictionary(
                entry => entry.Key,
                entry =>
                    entry
                        .Value!
                        .Errors.Select(error =>
                            string.IsNullOrWhiteSpace(error.ErrorMessage)
                                ? "The supplied value is invalid."
                                : error.ErrorMessage
                        )
                        .ToArray()
            );

        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(
            new Microsoft.AspNetCore.Mvc.ValidationProblemDetails(errors)
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Request validation failed.",
            }
        );
    };
});
builder.Services.AddEndpointsApiExplorer();

// Configure authorization policies for role-based and entitlement-based access control.
builder.Services.AddScoped<
    Microsoft.AspNetCore.Authorization.IAuthorizationHandler,
    MenuGreen.API.Authorization.EntitlementHandler
>();

builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new Microsoft.AspNetCore.Authorization.AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
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


// Configure CORS. Production never accepts wildcard or localhost origins.
var isDevelopment = builder.Environment.IsDevelopment();
var corsPolicyName = isDevelopment ? "AllowAll" : "ProductionPolicy";

var defaultOrigins = new[]
{
    "https://admin.menugreen.food",
    "https://www.menugreen.food",
    "https://menugreen.food",
};

var configuredOrigins =
    (
        builder.Configuration["AllowedOrigins"]
        ?? Environment.GetEnvironmentVariable("ALLOWED_ORIGINS")
    )?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? Array.Empty<string>();

if (!isDevelopment && configuredOrigins.Any(origin => origin == "*"))
{
    throw new InvalidOperationException("Wildcard CORS origins are forbidden in production.");
}

var invalidProductionOrigins = configuredOrigins.Where(origin =>
    !Uri.TryCreate(origin, UriKind.Absolute, out var uri)
    || !string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase)
    || !string.IsNullOrEmpty(uri.PathAndQuery.Trim('/'))
);
if (!isDevelopment && invalidProductionOrigins.Any())
{
    throw new InvalidOperationException(
        "Every production CORS origin must be an HTTPS origin without a path."
    );
}

var allowedOrigins = defaultOrigins
    .Concat(configuredOrigins)
    .Distinct(StringComparer.OrdinalIgnoreCase)
    .ToArray();

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        corsPolicyName,
        policy =>
        {
            if (isDevelopment)
            {
                policy
                    .SetIsOriginAllowed(origin => true)
                    .AllowAnyMethod()
                    .AllowAnyHeader();
            }
            else
            {
                policy
                    .WithOrigins(allowedOrigins)
                    .AllowAnyMethod()
                    .AllowAnyHeader();
            }
        }
    );
});

var trustProxyHeaders =
    bool.TryParse(
        builder.Configuration["TrustProxyHeaders"]
            ?? Environment.GetEnvironmentVariable("TRUST_PROXY_HEADERS"),
        out var parsedTrustProxyHeaders
    ) && parsedTrustProxyHeaders;

if (trustProxyHeaders)
{
    builder.Services.Configure<ForwardedHeadersOptions>(options =>
    {
        options.ForwardedHeaders =
            ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
        options.ForwardLimit = 2;
        options.KnownNetworks.Clear();
        options.KnownProxies.Clear();
    });
}

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

// 2. Configure JWT Authentication. Secret aliases support conventional deploy env names.
var secretKey =
    builder.Configuration["JwtSettings:SecretKey"]
    ?? Environment.GetEnvironmentVariable("JWT_SECRET_KEY");
if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");
}
var key = Encoding.UTF8.GetBytes(secretKey);
if (key.Length < 32)
{
    throw new InvalidOperationException("JwtSettings:SecretKey must contain at least 32 bytes.");
}

var jwtIssuer = builder.Configuration["JwtSettings:Issuer"];
var jwtAudience = builder.Configuration["JwtSettings:Audience"];
if (
    !isDevelopment
    && (string.IsNullOrWhiteSpace(jwtIssuer) || string.IsNullOrWhiteSpace(jwtAudience))
)
{
    throw new InvalidOperationException(
        "JwtSettings:Issuer and JwtSettings:Audience are required in production."
    );
}

builder
    .Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = !isDevelopment;
        options.SaveToken = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = !string.IsNullOrWhiteSpace(jwtIssuer),
            ValidIssuer = jwtIssuer,
            ValidateAudience = !string.IsNullOrWhiteSpace(jwtAudience),
            ValidAudience = jwtAudience,
            ValidateLifetime = true,
            RequireExpirationTime = true,
            RequireSignedTokens = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
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
    options.OnRejected = async (context, cancellationToken) =>
    {
        context.HttpContext.Response.ContentType = "application/problem+json";
        if (
            context.Lease.TryGetMetadata(
                MetadataName.RetryAfter,
                out var retryAfter
            )
        )
        {
            context.HttpContext.Response.Headers.RetryAfter = Math
                .Ceiling(retryAfter.TotalSeconds)
                .ToString(System.Globalization.CultureInfo.InvariantCulture);
        }

        await context.HttpContext.Response.WriteAsJsonAsync(
            new
            {
                type = "https://httpstatuses.com/429",
                title = "Too many requests.",
                status = StatusCodes.Status429TooManyRequests,
            },
            cancellationToken
        );
    };

    // 1. Global Limiter: 100 requests per 1 minute per IP
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var partitionKey =
            httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            ?? httpContext.Connection.RemoteIpAddress?.ToString()
            ?? "unknown-client";
        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey,
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

    // 5. Payment webhooks: tolerate provider retries while limiting abuse.
    options.AddPolicy(
        "WebhookPolicy",
        httpContext =>
        {
            var ipAddress = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
            return RateLimitPartition.GetFixedWindowLimiter(
                ipAddress,
                _ => new FixedWindowRateLimiterOptions
                {
                    AutoReplenishment = true,
                    PermitLimit = 60,
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

if (trustProxyHeaders)
{
    app.UseForwardedHeaders();
}

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
            logger.LogCritical(
                "[MIGRATION] DRIFT DETECTED: {Count} migration(s) are recorded in __EFMigrationsHistory but are NOT present in the running DLL: [{List}]. "
                    + "Startup is being stopped. Roll back the image or reconcile the migration history through an approved database change.",
                unknownInHistory.Count,
                string.Join(", ", unknownInHistory)
            );

            throw new InvalidOperationException(
                "Database migration history contains entries unknown to this application build.");
        }
    }
    catch (InvalidOperationException)
    {
        throw;
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

var enableSwagger =
    app.Environment.IsDevelopment()
    || (
        bool.TryParse(
            builder.Configuration["EnableSwagger"]
                ?? Environment.GetEnvironmentVariable("ENABLE_SWAGGER"),
            out var parsedEnableSwagger
        ) && parsedEnableSwagger
    );
if (enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

var enableMetrics =
    app.Environment.IsDevelopment()
    || (
        bool.TryParse(
            builder.Configuration["AspNetCoreMetrics"]
                ?? Environment.GetEnvironmentVariable("ASPNETCORE_METRICS"),
            out var parsedEnableMetrics
        ) && parsedEnableMetrics
    );
var metricsAuthToken =
    builder.Configuration["Metrics:AuthToken"]
    ?? Environment.GetEnvironmentVariable("METRICS_AUTH_TOKEN");

if (enableMetrics && !app.Environment.IsDevelopment() && string.IsNullOrWhiteSpace(metricsAuthToken))
{
    throw new InvalidOperationException(
        "METRICS_AUTH_TOKEN is required when production metrics are enabled."
    );
}

if (enableMetrics)
{
    app.UseWhen(
        context => context.Request.Path.Equals("/metrics", StringComparison.OrdinalIgnoreCase),
        metricsApp =>
            metricsApp.Use(async (context, next) =>
            {
                if (!app.Environment.IsDevelopment())
                {
                    var suppliedToken = context.Request.Headers["X-Metrics-Key"].ToString();
                    if (
                        suppliedToken.Length is 0 or > 512
                        || !FixedTimeEquals(suppliedToken, metricsAuthToken!)
                    )
                    {
                        context.Response.StatusCode = StatusCodes.Status404NotFound;
                        return;
                    }
                }

                await next();
            })
    );
    app.UseMetricServer();
    app.UseHttpMetrics();
}

app.Use(async (context, next) =>
{
    context.Response.OnStarting(() =>
    {
        var headers = context.Response.Headers;
        headers.XContentTypeOptions = "nosniff";
        headers.XFrameOptions = "DENY";
        headers["Referrer-Policy"] = "no-referrer";
        headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=(self)";

        if (!app.Environment.IsDevelopment())
        {
            headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
            if (context.Request.IsHttps)
            {
                headers.StrictTransportSecurity = "max-age=31536000; includeSubDomains";
            }
        }

        if (
            context.Request.Path.StartsWithSegments("/api/Auth")
            || context.Response.StatusCode >= StatusCodes.Status400BadRequest
        )
        {
            headers.CacheControl = "no-store";
            headers.Pragma = "no-cache";
        }

        return Task.CompletedTask;
    });

    await next();
});

app.Use(async (context, next) =>
{
    var requestLimit = context.Request.Path.StartsWithSegments("/api/Cv/analyze")
        ? MultipartRequestBodyBytes
        : DefaultRequestBodyBytes;

    if (context.Request.ContentLength > requestLimit)
    {
        context.Response.StatusCode = StatusCodes.Status413PayloadTooLarge;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsJsonAsync(
            new
            {
                type = "https://httpstatuses.com/413",
                title = "Request payload is too large.",
                status = StatusCodes.Status413PayloadTooLarge,
                maxBytes = requestLimit,
            },
            context.RequestAborted
        );
        return;
    }

    await next();
});

// HTTPS redirection handled by reverse proxy (nginx in docker-compose)

app.UseRouting();
app.UseCors(isDevelopment ? "AllowAll" : "ProductionPolicy");
app.UseAuthentication(); // MUST BE BEFORE UseAuthorization
app.UseRateLimiter();
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
            if (!app.Environment.IsDevelopment())
            {
                await context.Response.WriteAsJsonAsync(
                    new { status = report.Status.ToString() }
                );
                return;
            }

            await context.Response.WriteAsJsonAsync(
                new
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
                }
            );
        },
    }
).AllowAnonymous();

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
).AllowAnonymous();

app.MapHealthChecks(
    "/health/live",
    new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions { Predicate = _ => false }
).AllowAnonymous();

app.Run();

static bool FixedTimeEquals(string supplied, string expected)
{
    var suppliedBytes = Encoding.UTF8.GetBytes(supplied);
    var expectedBytes = Encoding.UTF8.GetBytes(expected);
    return suppliedBytes.Length == expectedBytes.Length
        && System.Security.Cryptography.CryptographicOperations.FixedTimeEquals(
            suppliedBytes,
            expectedBytes
        );
}

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
