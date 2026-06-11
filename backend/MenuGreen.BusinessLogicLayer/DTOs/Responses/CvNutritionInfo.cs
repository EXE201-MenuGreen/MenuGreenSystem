using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CvNutritionInfo
    {
        [JsonPropertyName("tong_calories")]
        public double TongCalories { get; set; }

        [JsonPropertyName("protein_g")]
        public double ProteinG { get; set; }

        [JsonPropertyName("carbs_g")]
        public double CarbsG { get; set; }

        [JsonPropertyName("fat_g")]
        public double FatG { get; set; }

        [JsonPropertyName("fiber_g")]
        public double FiberG { get; set; }
    }
}
