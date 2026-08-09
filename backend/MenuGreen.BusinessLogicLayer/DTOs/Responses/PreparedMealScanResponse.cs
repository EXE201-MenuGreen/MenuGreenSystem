using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class PreparedMealScanResponse
    {
        [JsonPropertyName("job_id")]
        public string JobId { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        [JsonPropertyName("message")]
        public string Message { get; set; } = string.Empty;

        [JsonPropertyName("steps")]
        public List<PreparedMealScanStep> Steps { get; set; } = new();

        [JsonPropertyName("result")]
        public PreparedMealScanResult? Result { get; set; }
    }

    public class PreparedMealScanStep
    {
        [JsonPropertyName("key")]
        public string Key { get; set; } = string.Empty;

        [JsonPropertyName("label")]
        public string Label { get; set; } = string.Empty;

        [JsonPropertyName("state")]
        public string State { get; set; } = string.Empty;
    }

    public class PreparedMealScanResult
    {
        [JsonPropertyName("job_id")]
        public string JobId { get; set; } = string.Empty;

        [JsonPropertyName("request_id")]
        public string RequestId { get; set; } = string.Empty;

        [JsonPropertyName("analysis_type")]
        public string AnalysisType { get; set; } = string.Empty;

        [JsonPropertyName("dish_name")]
        public string DishName { get; set; } = string.Empty;

        [JsonPropertyName("dish_name_key")]
        public string DishNameKey { get; set; } = string.Empty;

        [JsonPropertyName("dish_confidence")]
        public double DishConfidence { get; set; }

        [JsonPropertyName("estimated_total_grams")]
        public double EstimatedTotalGrams { get; set; }

        [JsonPropertyName("ingredients")]
        public List<PreparedMealIngredient> Ingredients { get; set; } = new();

        [JsonPropertyName("total_macros")]
        public PreparedMealMacros TotalMacros { get; set; } = new();

        [JsonPropertyName("estimation_note")]
        public string EstimationNote { get; set; } = string.Empty;
    }

    public class PreparedMealIngredient
    {
        [JsonPropertyName("ingredient_id")]
        public string IngredientId { get; set; } = string.Empty;

        [JsonPropertyName("name")]
        public string Name { get; set; } = string.Empty;

        [JsonPropertyName("estimated_grams")]
        public double EstimatedGrams { get; set; }

        [JsonPropertyName("detection_confidence")]
        public double DetectionConfidence { get; set; }

        [JsonPropertyName("nutrition")]
        public PreparedMealNutrition Nutrition { get; set; } = new();
    }

    public class PreparedMealNutrition
    {
        [JsonPropertyName("macros")]
        public PreparedMealMacros Macros { get; set; } = new();

        [JsonPropertyName("data_source")]
        public string DataSource { get; set; } = string.Empty;

        [JsonPropertyName("confidence")]
        public double Confidence { get; set; }
    }

    public class PreparedMealMacros
    {
        [JsonPropertyName("calories_kcal")]
        public double CaloriesKcal { get; set; }

        [JsonPropertyName("protein_g")]
        public double ProteinG { get; set; }

        [JsonPropertyName("carbs_g")]
        public double CarbsG { get; set; }

        [JsonPropertyName("fat_g")]
        public double FatG { get; set; }

        [JsonPropertyName("fiber_g")]
        public double? FiberG { get; set; }
    }
}
