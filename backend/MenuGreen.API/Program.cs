using System.Text;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MenuGreen.DataAccessLayer;
using MenuGreen.BusinessLogicLayer;
using MenuGreen.DataAccessLayer.Context;
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
builder.Services.AddBusinessLogicLayer();

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Configure authorization policies for role-based access control.
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("UserOnly", policy => policy.RequireRole("User", "Admin"));
});

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
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
var secretKey = builder.Configuration["JwtSettings:SecretKey"] ?? "super_secret_key_menu_green_1234567890_super_long";
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
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["JwtSettings:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["JwtSettings:Audience"],
        ClockSkew = TimeSpan.Zero
    };
});
var app = builder.Build();
var enableSwagger = builder.Configuration.GetValue<bool>("Swagger:Enabled");

// Seed data: run backend/seeddata.sql in pgAdmin after migrations.

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment() || enableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Enable CORS
app.UseCors("AllowAll");

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication(); // MUST BE BEFORE UseAuthorization
app.UseAuthorization();

app.MapControllers();

app.Run();
