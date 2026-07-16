using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class NutritionAssistantFeedbackResponse
    {
        public string FeedbackId { get; set; } = string.Empty;
        public DateTimeOffset? CreatedAt { get; set; }
    }

    public class NutritionAssistantMealPlan7dResponse
    {
        public string UserId { get; set; } = string.Empty;
        public int TotalDays { get; set; }
        public int TotalItems { get; set; }
        public IReadOnlyList<NutritionAssistantMealPlanItemResponse> Plan { get; set; } =
            Array.Empty<NutritionAssistantMealPlanItemResponse>();
    }

    public class NutritionAssistantMealPlanItemResponse
    {
        public string PlanDate { get; set; } = string.Empty;
        public string MealType { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public decimal CaloriesKcal { get; set; }
        public int? EstimatedPriceVnd { get; set; }
        public int? PrepTimeMin { get; set; }
        public int? CookTimeMin { get; set; }
        public string Source { get; set; } = string.Empty;
    }

    public class AiWorkerCrawlerNormalizeResponse
    {
        [JsonPropertyName("total_recipes")]
        public int TotalRecipes { get; set; }

        [JsonPropertyName("total_ingredients")]
        public int TotalIngredients { get; set; }

        [JsonPropertyName("normalized")]
        public JsonElement Normalized { get; set; }
    }

    public class AiWorkerCrawlerIngestResponse
    {
        [JsonPropertyName("recipes_inserted")]
        public int RecipesInserted { get; set; }

        [JsonPropertyName("recipes_updated")]
        public int RecipesUpdated { get; set; }

        [JsonPropertyName("ingredients_inserted")]
        public int IngredientsInserted { get; set; }

        [JsonPropertyName("recipe_links_inserted")]
        public int RecipeLinksInserted { get; set; }

        [JsonPropertyName("skipped")]
        public int Skipped { get; set; }
    }

    public class AiWorkerCreateTrainingSampleResponse
    {
        public string SampleId { get; set; } = string.Empty;
        public string Status { get; set; } = "pending";
        public DateTimeOffset? CreatedAt { get; set; }
    }

    public class AiWorkerTrainingSampleListResponse
    {
        public IReadOnlyList<AiWorkerTrainingSampleResponse> Items { get; set; } =
            Array.Empty<AiWorkerTrainingSampleResponse>();
    }

    public class AiWorkerTrainingSampleResponse
    {
        public string Id { get; set; } = string.Empty;
        public string? FeedbackId { get; set; }
        public string Source { get; set; } = string.Empty;
        public string InputText { get; set; } = string.Empty;
        public JsonElement? ContextJson { get; set; }
        public string ExpectedOutput { get; set; } = string.Empty;
        public IReadOnlyList<string> Labels { get; set; } = Array.Empty<string>();
        public string Status { get; set; } = string.Empty;
        public string? ReviewedBy { get; set; }
        public DateTimeOffset? ReviewedAt { get; set; }
        public DateTimeOffset? CreatedAt { get; set; }
        public DateTimeOffset? UpdatedAt { get; set; }
    }
}
