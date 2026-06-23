using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller for managing Subscription Plans.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    [Authorize(Policy = "AdminOnly")]
    public class SubscriptionPlanController : ControllerBase
    {
        private readonly ISubscriptionPlanService _service;

        public SubscriptionPlanController(ISubscriptionPlanService service)
        {
            _service = service;
        }

        /// <summary>
        /// Get list of subscription plan policies (can filter by status).
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] bool? isActive = null)
        {
            try
            {
                return Ok(await _service.GetAllAsync(isActive));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }


        /// <summary>
        /// Get detailed policy of a subscription plan by Id.
        /// </summary>
        [HttpGet("{id:guid}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                return Ok(await _service.GetByIdAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get list of features for a subscription plan.
        /// </summary>
        [HttpGet("{id:guid}/features")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPlanFeatures(Guid id)
        {
            try
            {
                return Ok(await _service.GetPlanFeaturesAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Get active status of a subscription plan.
        /// </summary>
        [HttpGet("{id:guid}/status")]
        public async Task<IActionResult> GetPlanStatus(Guid id)
        {
            try
            {
                return Ok(await _service.GetPlanStatusAsync(id));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Create new subscription plan policy.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SubscriptionPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _service.CreateAsync(request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Update plan policy price and duration.
        /// </summary>
        [HttpPut("{id:guid}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] SubscriptionPlanUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _service.UpdateAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Delete unused subscription plan policy.
        /// </summary>
        [HttpDelete("{id:guid}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                await _service.DeleteAsync(id);
                return Ok(new { Message = "Deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        /// <summary>
        /// Enable or disable subscription plan policy.
        /// </summary>
        [HttpPatch("{id:guid}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] SubscriptionPlanStatusRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            try
            {
                return Ok(await _service.UpdateStatusAsync(id, request));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
