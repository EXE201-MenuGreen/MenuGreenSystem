using System;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <summary>Shared BMR/TDEE/macro calculations for Profile and HealthProfile services.</summary>
    public static class HealthProfileMetricsCalculator
    {
        public static void Apply(HealthProfile healthProfile, string? gender, DateOnly? dateOfBirth, int? targetCaloriesOverride = null)
        {
            if (!healthProfile.HeightCm.HasValue || !healthProfile.WeightKg.HasValue)
            {
                return;
            }

            var age = CalculateAge(dateOfBirth);
            var bmr = CalculateBmr(healthProfile.WeightKg.Value, healthProfile.HeightCm.Value, age, gender);
            var multiplier = GetActivityMultiplier(healthProfile.ActivityLevel);

            healthProfile.Bmi = CalculateBmi(healthProfile.WeightKg.Value, healthProfile.HeightCm.Value);
            healthProfile.BmrKcal = (int)Math.Round(bmr, MidpointRounding.AwayFromZero);
            var calculatedTdee = (int)Math.Round(bmr * multiplier, MidpointRounding.AwayFromZero);
            healthProfile.TdeeKcal = Math.Max(calculatedTdee, 1200);
            healthProfile.TargetCalories = targetCaloriesOverride
                ?? CalculateTargetCalories(healthProfile.TdeeKcal.Value, healthProfile.Goal);

            ApplyMacroTargets(healthProfile);
        }

        public static int CalculateAge(DateOnly? dateOfBirth)
        {
            if (!dateOfBirth.HasValue)
            {
                return 25;
            }

            var age = DateTime.Today.Year - dateOfBirth.Value.Year;
            if (dateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today.AddYears(-age)))
            {
                age--;
            }

            return age;
        }

        public static double CalculateBmr(decimal weightKg, decimal heightCm, int age, string? gender)
        {
            var baseBmr = (10 * (double)weightKg) + (6.25 * (double)heightCm) - (5 * age);
            var genderBonus = gender?.Trim().ToLower() is "male" or "nam" ? 5 : -161;
            return baseBmr + genderBonus;
        }

        public static double GetActivityMultiplier(string? activityLevel)
        {
            return activityLevel?.Trim().ToLower() switch
            {
                "sedentary" => 1.2,
                "light" or "lightlyactive" or "lightly active" => 1.375,
                "moderate" or "moderatelyactive" or "moderately active" => 1.55,
                "active" or "veryactive" or "very active" => 1.725,
                _ => 1.2
            };
        }

        public static decimal CalculateBmi(decimal weightKg, decimal heightCm)
        {
            var heightMeters = (double)heightCm / 100d;
            return (decimal)Math.Round((double)weightKg / (heightMeters * heightMeters), 2);
        }

        public static int CalculateTargetCalories(int tdeeKcal, string? goal)
        {
            return tdeeKcal + (goal?.Trim().ToLower() switch
            {
                "gain weight" or "gainweight" => 300,
                "lose weight" or "loseweight" => -500,
                "build muscle" or "buildmuscle" => 200,
                _ => 0
            });
        }

        public static void ApplyMacroTargets(HealthProfile healthProfile)
        {
            var goal = healthProfile.Goal?.Trim().ToLower();
            var proteinRatio = goal is "build muscle" or "buildmuscle" ? 0.35 : 0.30;
            var fatRatio = goal is "build muscle" or "buildmuscle" ? 0.20 : 0.30;
            var carbsRatio = goal is "build muscle" or "buildmuscle" ? 0.45 : 0.40;

            var targetCalories = (double)(healthProfile.TargetCalories ?? 0);
            var proteinG = (targetCalories * proteinRatio) / 4;

            if (healthProfile.WeightKg.HasValue && healthProfile.WeightKg.Value > 0)
            {
                var weight = (double)healthProfile.WeightKg.Value;
                var minProtein = weight * 0.8;
                var maxProtein = weight * 2.2;
                if (proteinG < minProtein)
                {
                    proteinG = minProtein;
                }
                else if (proteinG > maxProtein)
                {
                    proteinG = maxProtein;
                }
            }

            healthProfile.TargetProteinG = (int)Math.Round(proteinG, MidpointRounding.AwayFromZero);
            healthProfile.TargetCarbsG = (int)Math.Round((targetCalories * carbsRatio) / 4, MidpointRounding.AwayFromZero);
            healthProfile.TargetFatG = (int)Math.Round((targetCalories * fatRatio) / 9, MidpointRounding.AwayFromZero);
        }
    }
}
