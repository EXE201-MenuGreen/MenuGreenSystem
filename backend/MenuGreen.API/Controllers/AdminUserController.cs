using System;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MenuGreen.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin")]
    public class AdminUserController : ControllerBase
    {
        private readonly IAdminUserService _service;

        public AdminUserController(IAdminUserService service)
        {
            _service = service;
        }

        // Lấy danh sách tất cả người dùng để admin quản lý.
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            return Ok(await _service.GetAllAsync());
        }

        // Lấy chi tiết một người dùng theo Id.
        [HttpGet("{userId:guid}")]
        public async Task<IActionResult> GetById(Guid userId)
        {
            try
            {
                return Ok(await _service.GetByIdAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Khóa tài khoản user vi phạm.
        [HttpPatch("{userId:guid}/lock")]
        public async Task<IActionResult> Lock(Guid userId)
        {
            try
            {
                return Ok(await _service.LockAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }

        // Mở khóa tài khoản user sau khi xử lý xong.
        [HttpPatch("{userId:guid}/unlock")]
        public async Task<IActionResult> Unlock(Guid userId)
        {
            try
            {
                return Ok(await _service.UnlockAsync(userId));
            }
            catch (Exception ex)
            {
                return BadRequest(new { Message = ex.Message });
            }
        }
    }
}
