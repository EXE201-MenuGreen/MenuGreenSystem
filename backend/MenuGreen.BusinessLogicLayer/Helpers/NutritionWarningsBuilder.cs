using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.Helpers
{
    public static class NutritionWarningsBuilder
    {
        private const decimal MacroDeviationThreshold = 0.15m;

        public static List<string> Build(
            decimal totalCalories,
            decimal targetCalories,
            decimal totalProtein,
            decimal targetProtein,
            decimal totalCarbs,
            decimal targetCarbs,
            decimal totalFat,
            decimal targetFat)
        {
            var messages = new List<string>();

            if (targetCalories > 0)
            {
                var calorieThreshold = Math.Max(100m, targetCalories * 0.10m);
                if (Math.Abs(totalCalories - targetCalories) > calorieThreshold)
                {
                    messages.Add("Calorie intake deviates more than 10% from daily target.");
                }
            }

            AddMacroWarning(messages, "Protein", totalProtein, targetProtein);
            AddMacroWarning(messages, "Carbs", totalCarbs, targetCarbs);
            AddMacroWarning(messages, "Fat", totalFat, targetFat);

            return messages;
        }

        private static void AddMacroWarning(
            List<string> messages,
            string label,
            decimal total,
            decimal target)
        {
            if (target <= 0) return;

            var deviation = Math.Abs(total - target);
            if (deviation <= target * MacroDeviationThreshold) return;

            if (total > target)
            {
                messages.Add($"{label} exceeds target ({total:0.#}g / {target:0.#}g).");
                return;
            }

            messages.Add($"{label} below target ({total:0.#}g / {target:0.#}g).");
        }
    }
}
