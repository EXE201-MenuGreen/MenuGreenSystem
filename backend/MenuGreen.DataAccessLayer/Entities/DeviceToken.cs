using System;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class DeviceToken
    {
        [Key]
        public Guid Id { get; set; }
        
        [Required]
        public Guid UserId { get; set; }
        
        [Required]
        [MaxLength(500)]
        public string Token { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string? DeviceType { get; set; }
        
        [MaxLength(100)]
        public string? DeviceName { get; set; }
        
        [MaxLength(200)]
        public string? AppVersion { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastUsedAt { get; set; }
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
        
        public User User { get; set; } = null!;
    }
}
