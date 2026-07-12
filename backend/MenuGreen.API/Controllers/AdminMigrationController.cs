using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MenuGreen.DataAccessLayer.Context;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MenuGreen.API.Controllers;

/// <summary>
/// Admin endpoints for managing EF Core migrations at runtime.
/// Used as a break-glass tool when an operator wants to inspect or trigger
/// migration apply without restarting the container. The startup auto-apply
/// block in Program.cs still runs independently; this controller is additive.
/// </summary>
[ApiController]
[Route("api/admin/migrations")]
[Authorize(Policy = "AdminOnly")]
public class AdminMigrationController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly ILogger<AdminMigrationController> _logger;

    public AdminMigrationController(
        ApplicationDbContext db,
        ILogger<AdminMigrationController> logger)
    {
        _db = db;
        _logger = logger;
    }

    /// <summary>
    /// Snapshot of migration state visible to the running DLL: applied,
    /// pending, and any drift (history rows the DLL no longer recognizes).
    /// </summary>
    [HttpGet("status")]
    public async Task<IActionResult> GetStatus(CancellationToken ct)
    {
        var gitSha = Environment.GetEnvironmentVariable("GIT_SHA") ?? "<unknown>";
        var dllVersion = typeof(ApplicationDbContext).Assembly
            .GetCustomAttributes(typeof(System.Reflection.AssemblyFileVersionAttribute), false)
            .OfType<System.Reflection.AssemblyFileVersionAttribute>()
            .FirstOrDefault()?.Version ?? "<unknown>";

        var applied = (await _db.Database.GetAppliedMigrationsAsync(ct)).ToList();
        var pending = (await _db.Database.GetPendingMigrationsAsync(ct)).ToList();
        var known = (await _db.Database.GetMigrationsAsync(ct)).ToHashSet();
        var drift = applied.Where(id => !known.Contains(id)).ToList();

        return Ok(new
        {
            gitSha,
            dataAccessLayerVersion = dllVersion,
            applied,
            pending,
            drift,
        });
    }

    /// <summary>
    /// Raw contents of __EFMigrationsHistory. Useful when you want to see the
    /// exact rows EF will use to decide what's pending, including ones that
    /// are absent from the running DLL (drift).
    /// </summary>
    [HttpGet("history")]
    public async Task<IActionResult> GetHistory(CancellationToken ct)
    {
        var rows = await _db.Database
            .SqlQueryRaw<MigrationRow>(
                "SELECT \"MigrationId\" AS \"MigrationId\", \"ProductVersion\" AS \"ProductVersion\" FROM \"__EFMigrationsHistory\" ORDER BY \"MigrationId\"")
            .ToListAsync(ct);

        return Ok(new
        {
            count = rows.Count,
            rows,
        });
    }

    /// <summary>
    /// Trigger db.Database.Migrate() at runtime. Idempotent: calling on a
    /// fully-applied DB returns newlyApplied=[]. On failure, returns 500 with
    /// the underlying exception message (does NOT throw, so the operator can
    /// see the error and decide next steps).
    /// </summary>
    [HttpPost("apply")]
    public async Task<IActionResult> Apply(CancellationToken ct)
    {
        var gitSha = Environment.GetEnvironmentVariable("GIT_SHA") ?? "<unknown>";
        var before = (await _db.Database.GetAppliedMigrationsAsync(ct)).ToHashSet();

        _logger.LogInformation(
            "[MIGRATION-API] Apply triggered by {User}. Applied before ({Count}): [{List}]",
            User?.Identity?.Name ?? "<unknown>",
            before.Count,
            string.Join(", ", before.OrderBy(x => x)));

        try
        {
            await _db.Database.MigrateAsync(ct);

            var after = (await _db.Database.GetAppliedMigrationsAsync(ct)).ToList();
            var newly = after.Where(id => !before.Contains(id)).ToList();

            _logger.LogInformation(
                "[MIGRATION-API] Applied {Count} new migration(s): [{List}]",
                newly.Count,
                string.Join(", ", newly));

            return Ok(new
            {
                gitSha,
                appliedBefore = before.OrderBy(x => x),
                appliedAfter = after.OrderBy(x => x),
                newlyApplied = newly,
                message = newly.Count == 0
                    ? "Database is already up to date."
                    : "Migrations applied successfully.",
            });
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "[MIGRATION-API] FATAL: Apply failed for GitSHA={GitSha}.", gitSha);
            return StatusCode(500, new
            {
                error = ex.Message,
                gitSha,
            });
        }
    }

    /// <summary>
    /// Row shape of the EF Core __EFMigrationsHistory table. Kept private to
    /// this controller since it's only used by /history.
    /// </summary>
    private record MigrationRow(string MigrationId, string ProductVersion);
}
