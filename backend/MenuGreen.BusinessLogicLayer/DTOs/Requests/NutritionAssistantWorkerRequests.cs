using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text.Json;

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
