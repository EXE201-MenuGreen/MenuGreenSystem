using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/admin/users/{userId:guid}/memberships")]
    [Authorize(Roles = "Admin")]
    public class AdminMembershipController : ControllerBase
    {
        private readonly IAdminMembershipService _service;

        public AdminMembershipController(IAdminMembershipService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> Get(Guid userId)
        {
            try
            {
                return Ok(await _service.GetAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Grant(Guid userId, [FromBody] AdminGrantMembershipRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetAdminId(out var adminUserId)) return Unauthorized();
            try
            {
                return Ok(await _service.GrantAsync(adminUserId, userId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("{subscriptionId:guid}/extend")]
        public async Task<IActionResult> Extend(
            Guid userId,
            Guid subscriptionId,
            [FromBody] AdminExtendMembershipRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetAdminId(out var adminUserId)) return Unauthorized();
            try
            {
                return Ok(await _service.ExtendAsync(adminUserId, userId, subscriptionId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        [HttpPost("{subscriptionId:guid}/revoke")]
        public async Task<IActionResult> Revoke(
            Guid userId,
            Guid subscriptionId,
            [FromBody] AdminRevokeMembershipRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetAdminId(out var adminUserId)) return Unauthorized();
            try
            {
                return Ok(await _service.RevokeAsync(adminUserId, userId, subscriptionId, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        private bool TryGetAdminId(out Guid adminUserId)
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(raw, out adminUserId);
        }
    }
}
