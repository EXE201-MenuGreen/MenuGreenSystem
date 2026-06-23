using System;
using System.Security.Claims;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    /// <summary>
    /// Controller for Vietnamese traditional portion converter to standard gram/ml units.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PortionConverterController : ControllerBase
    {
        private readonly IPortionConverterService _service;

        public PortionConverterController(IPortionConverterService service)
        {
            _service = service;
        }

        /// <summary>
        /// Get list of all default Vietnamese traditional portion units with descriptions.
        /// </summary>
        [HttpGet("units")]
        public async Task<IActionResult> GetDefaultUnits()
        {
            var result = await _service.GetDefaultUnitsAsync();
            return Ok(result);
        }

        /// <summary>
        /// Get custom portion units defined for a specific food item.
        /// </summary>
        [HttpGet("units/food/{foodId:guid}")]
        public async Task<IActionResult> GetFoodUnits(Guid foodId)
        {
            var result = await _service.GetUnitsByFoodAsync(foodId);
            return Ok(result);
        }

        /// <summary>
        /// Convert traditional portion quantity to gram/ml and calculate corresponding Calo/Macro values.
        /// </summary>
        [HttpPost("convert")]
        public async Task<IActionResult> Convert([FromBody] PortionConvertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            TryGetUserId(out var userId); // userId nullable

            try
            {
                var result = await _service.ConvertPortionAsync(request, userId == Guid.Empty ? null : userId);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Get personalized custom portion units created by user.
        /// </summary>
        [HttpGet("custom-units")]
        public async Task<IActionResult> GetCustomUnits()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            var result = await _service.GetCustomUnitsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Register a new custom portion unit (Example: "Ceramic bowl" = 500g).
        /// </summary>
        [HttpPost("custom-units")]
        public async Task<IActionResult> CreateCustomUnit([FromBody] CustomUserPortionUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.CreateCustomUnitAsync(userId, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Update weight parameters of a custom personal portion unit.
        /// </summary>
        [HttpPut("custom-units/{id:guid}")]
        public async Task<IActionResult> UpdateCustomUnit(Guid id, [FromBody] CustomUserPortionUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.UpdateCustomUnitAsync(userId, id, request);
                return Ok(result);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        /// <summary>
        /// Delete a custom personal portion unit.
        /// </summary>
        [HttpDelete("custom-units/{id:guid}")]
        public async Task<IActionResult> DeleteCustomUnit(Guid id)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            try
            {
                var result = await _service.DeleteCustomUnitAsync(userId, id);
                return Ok(new { success = result, message = "Custom unit deleted successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        private bool TryGetUserId(out Guid userId)
        {
            userId = Guid.Empty;
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }
    }
}
