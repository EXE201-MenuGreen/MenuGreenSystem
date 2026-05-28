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
    [Route("api/[controller]")]
    [Authorize]
    public class AllergyController : ControllerBase
    {
        private readonly IAllergyService _service;
        public AllergyController(IAllergyService service) => _service = service;

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            return Ok(await _service.GetAllAsync(id));
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            return Ok(await _service.CreateAsync(id, request));
        }

        [HttpPut("{allergyId:guid}")]
        public async Task<IActionResult> Update(Guid allergyId, [FromBody] AllergyUpsertRequest request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            return Ok(await _service.UpdateAsync(id, allergyId, request));
        }

        [HttpDelete("{allergyId:guid}")]
        public async Task<IActionResult> Delete(Guid allergyId)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userId, out var id)) return Unauthorized();
            await _service.DeleteAsync(id, allergyId);
            return Ok();
        }
    }
}
