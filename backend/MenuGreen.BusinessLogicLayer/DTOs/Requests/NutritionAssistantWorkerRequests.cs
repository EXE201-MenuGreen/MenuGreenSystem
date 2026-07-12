using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class NutritionAssistantFeedbackRequest
    {
        public string? ConversationId { get; set; }
        public string? MessageId { get; set; }
        public string? ThreadId { get; set; }

        [Required]
        [RegularExpression("^(thumbs_up|thumbs_down|correction|rating)$")]
        public string FeedbackType { get; set; } = "thumbs_up";

        [Range(1, 5)]
        public int? Rating { get; set; }

        [MaxLength(2000)]
        public string? UserNote { get; set; }

        [MaxLength(8000)]
        public string? AssistantResponse { get; set; }

        [MaxLength(8000)]
        public string? CorrectedResponse { get; set; }

        [RegularExpression("^(nutrition_chat|meal_recommendation|meal_plan_generation|ingredient_utilization|office_program|gym_program)$")]
        public string? FeatureArea { get; set; } = "nutrition_chat";
    }

    public class NutritionAssistantMealPlan7dRequest
    {
        [Range(1000, 2000000)]
        public int BudgetVndPerDay { get; set; }

        [Range(5, 240)]
        public int MaxCookTimeMin { get; set; } = 60;

        [Range(800, 6000)]
        public int TargetCaloriesPerDay { get; set; } = 2000;
    }

    public class AiWorkerRecommendationRequest
    {
        public string? Date { get; set; }

        [Range(0, int.MaxValue)]
        public int? BudgetVnd { get; set; }

        [RegularExpression("^(breakfast|lunch|dinner|snack|any)$")]
        public string? MealSlot { get; set; }

        [Range(0, int.MaxValue)]
        public int? MaxCookTimeMin { get; set; }

        [Range(0, int.MaxValue)]
        public int? TargetCalories { get; set; }

        public IReadOnlyList<string> ExcludeFoodIds { get; set; } = new List<string>();

        [Range(1, 50)]
        public int Limit { get; set; } = 5;
    }

    public class AiWorkerActionPayload
    {
        [JsonPropertyName("food_id")]
        public Guid? FoodId { get; set; }
        [JsonPropertyName("recipe_id")]
        public Guid? RecipeId { get; set; }
        [JsonPropertyName("meal_slot")]
        public string? MealSlot { get; set; }
        [JsonPropertyName("meal_type")]
        public string? MealType { get; set; }
        [JsonPropertyName("quantity_g")]
        public decimal? QuantityG { get; set; }
        [JsonPropertyName("quantity")]
        public decimal? Quantity { get; set; }
        [JsonPropertyName("unit")]
        public string? Unit { get; set; }
        [JsonPropertyName("notes")]
        public string? Notes { get; set; }
        [JsonPropertyName("logged_at")]
        public string? LoggedAt { get; set; }
        [JsonPropertyName("planned_date")]
        public string? PlannedDate { get; set; }
        [JsonPropertyName("scheduled_time")]
        public string? ScheduledTime { get; set; }
        [JsonPropertyName("date")]
        public string? Date { get; set; }
        [JsonPropertyName("time")]
        public string? Time { get; set; }
        [JsonPropertyName("budget_vnd")]
        public int? BudgetVnd { get; set; }
        [JsonPropertyName("budget_vnd_per_day")]
        public int? BudgetVndPerDay { get; set; }
        [JsonPropertyName("budget_per_meal_vnd")]
        public int? BudgetPerMealVnd { get; set; }
        [JsonPropertyName("max_cook_time_min")]
        public int? MaxCookTimeMin { get; set; }
        [JsonPropertyName("target_calories")]
        public int? TargetCalories { get; set; }
        [JsonPropertyName("target_calories_per_day")]
        public int? TargetCaloriesPerDay { get; set; }
        [JsonPropertyName("daily_target_calories")]
        public int? DailyTargetCalories { get; set; }
        [JsonPropertyName("calories_kcal")]
        public decimal? CaloriesKcal { get; set; }
        [JsonPropertyName("protein_g")]
        public decimal? ProteinG { get; set; }
        [JsonPropertyName("carbs_g")]
        public decimal? CarbsG { get; set; }
        [JsonPropertyName("fat_g")]
        public decimal? FatG { get; set; }
    }

    public class AiWorkerActionExecuteRequest
    {
        [Required]
        [RegularExpression("^(generate_meal_plan|replace_food|budget_optimize|schedule_meal|show_recipe|log_meal|ask_followup)$")]
        public string Type { get; set; } = "ask_followup";

        public AiWorkerActionPayload? Payload { get; set; }

        public bool Confirmed { get; set; }
    }

    public class AiWorkerCrawlerNormalizeRequest
    {
        [Required]
        public JsonElement Data { get; set; }
    }

    public class AiWorkerCrawlerIngestRequest
    {
        [Required]
        public JsonElement Normalized { get; set; }
    }

    public class AiWorkerCreateTrainingSampleRequest
    {
        public string? UserId { get; set; }
        public string? FeedbackId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Source { get; set; } = "user_feedback";

        [Required]
        [MinLength(1)]
        public string InputText { get; set; } = string.Empty;

        public JsonElement? ContextJson { get; set; }

        [Required]
        [MinLength(1)]
        public string ExpectedOutput { get; set; } = string.Empty;

        public IReadOnlyList<string> Labels { get; set; } = new List<string>();

        [RegularExpression("^(pending|approved|rejected|trained)$")]
        public string Status { get; set; } = "pending";
    }

    public class AiWorkerCreateSampleFromFeedbackRequest
    {
        public string? InputText { get; set; }
        public string? ExpectedOutput { get; set; }
        public IReadOnlyList<string> Labels { get; set; } = new List<string>();
    }

    public class AiWorkerReviewTrainingSampleRequest
    {
        [Required]
        [RegularExpression("^(approved|rejected|trained)$")]
        public string Status { get; set; } = "approved";

        public string? ReviewerUserId { get; set; }
        public string? ReviewNote { get; set; }
    }
}
