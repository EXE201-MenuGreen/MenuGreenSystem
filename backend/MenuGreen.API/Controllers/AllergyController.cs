using System;
using System.Collections.Generic;
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
    /// Controller for allergy profile management, allergy risk assessment, and safe food recommendations.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [Authorize(Policy = "UserOnly")]
    public class AllergyController : ControllerBase
    {
        private readonly IAllergyService _service;
        private readonly IAllergenMatchingService _allergenMatching;

        public AllergyController(IAllergyService service, IAllergenMatchingService allergenMatching)
        {
            _service = service;
            _allergenMatching = allergenMatching;
        }

        private bool TryGetUserId(out Guid userId)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            return Guid.TryParse(userIdString, out userId);
        }

        /// <summary>
        /// Get all allergies of the currently logged-in user.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.GetAllAsync(userId));
        }

        /// <summary>
        /// Add a new allergy entry for the user.
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.CreateAsync(userId, request));
        }

        /// <summary>
        /// Update an existing allergy entry.
        /// </summary>
        [HttpPut("{allergyId:guid}")]
        public async Task<IActionResult> Update(Guid allergyId, [FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateAsync(userId, allergyId, request));
        }

        /// <summary>
        /// Delete an allergy entry for the user.
        /// </summary>
        [HttpDelete("{allergyId:guid}")]
        public async Task<IActionResult> Delete(Guid allergyId)
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();
            await _service.DeleteAsync(userId, allergyId);
            return Ok();
        }

        /// <summary>
        /// Bulk update user allergen profile (e.g., after Onboarding completion or quick edit).
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] AllergyProfileUpdateRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            if (!TryGetUserId(out var userId)) return Unauthorized();
            return Ok(await _service.UpdateProfileAsync(userId, request.Allergens));
        }

        /// <summary>
        /// Get catalog of all standardized allergens supported by MenuGreen.
        /// </summary>
        [HttpGet("catalog")]
        public async Task<IActionResult> GetCatalog()
        {
            return Ok(await _service.GetCatalogAsync());
        }



    }
}
