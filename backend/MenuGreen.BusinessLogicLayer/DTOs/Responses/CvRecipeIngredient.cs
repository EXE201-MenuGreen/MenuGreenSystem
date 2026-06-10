using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CvRecipeIngredient
    {
        [JsonPropertyName("ten")]
        public string Ten { get; set; } = string.Empty;

        [JsonPropertyName("ten_ky_thuat")]
        public string TenKyThuat { get; set; } = string.Empty;

        [JsonPropertyName("khoi_luong_g")]
        public double KhoiLuongG { get; set; }
    }
}
