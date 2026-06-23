namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AnalyticsGoalAchievementResponse
    {
        public AchievementRates OverallAchievementRate { get; set; } = new();
        public List<WeeklyAchievement> WeeklyAchievementTrend { get; set; } = new();
        public Dictionary<string, AchievementRates> AchievementByUserSegment { get; set; } = new();
    }

    public class AchievementRates
    {
        public decimal CalorieGoal { get; set; }
        public decimal ProteinGoal { get; set; }
        public decimal CarbGoal { get; set; }
        public decimal FatGoal { get; set; }
        public decimal FiberGoal { get; set; }
    }

    public class WeeklyAchievement
    {
        public string Week { get; set; } = string.Empty;
        public decimal CalorieGoal { get; set; }
        public decimal ProteinGoal { get; set; }
        public decimal CarbGoal { get; set; }
        public decimal FatGoal { get; set; }
    }
}
