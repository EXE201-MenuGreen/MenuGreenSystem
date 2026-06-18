using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class CardActionRequest
    {
        [Required]
        public string Action { get; set; } = string.Empty; // "read", "save", "unsave", "dismiss"
    }
}
