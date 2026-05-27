using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class UpdateAvatarRequest
    {
        [Required(ErrorMessage = "Avatar URL is required.")]
        [Url(ErrorMessage = "Avatar URL must be a valid URL.")]
        public string AvatarUrl { get; set; } = string.Empty;
    }
}
