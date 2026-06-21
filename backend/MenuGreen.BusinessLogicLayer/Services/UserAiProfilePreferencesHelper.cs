using System;
using System.Collections.Generic;
using System.Text.Json;

namespace MenuGreen.BusinessLogicLayer.Services
{
    internal static class UserAiProfilePreferencesHelper
    {
        private const string AllergiesAcknowledgedKey = "allergiesAcknowledged";
        private const string VietnamRegionKey = "vietnamRegion";
        private const string MealContextKey = "mealContext";
        private const string BudgetPerMealVndKey = "budgetPerMealVnd";
        private const string PreferredPortionUnitsKey = "preferredPortionUnits";

        public static bool TryGetAllergiesAcknowledged(string? preferencesJson)
        {
            if (string.IsNullOrWhiteSpace(preferencesJson))
            {
                return false;
            }

            try
            {
                using var doc = JsonDocument.Parse(preferencesJson);
                if (doc.RootElement.TryGetProperty(AllergiesAcknowledgedKey, out var prop)
                    && prop.ValueKind == JsonValueKind.True)
                {
                    return true;
                }
            }
            catch (JsonException)
            {
                // Legacy plain-text preferences — not acknowledged via JSON flag.
            }

            return false;
        }

        public static string MergePreferences(
            string? existingJson,
            string? incomingPreferences,
            bool? allergiesAcknowledged,
            string? vietnamRegion = null,
            string? mealContext = null,
            int? budgetPerMealVnd = null,
            string? preferredPortionUnits = null)
        {
            var dict = new Dictionary<string, JsonElement>();

            if (!string.IsNullOrWhiteSpace(existingJson))
            {
                try
                {
                    using var doc = JsonDocument.Parse(existingJson);
                    if (doc.RootElement.ValueKind == JsonValueKind.Object)
                    {
                        foreach (var prop in doc.RootElement.EnumerateObject())
                        {
                            dict[prop.Name] = prop.Value.Clone();
                        }
                    }
                }
                catch (JsonException)
                {
                    if (!string.IsNullOrWhiteSpace(existingJson))
                    {
                        dict["legacyPreferences"] = JsonSerializer.SerializeToElement(existingJson);
                    }
                }
            }

            if (!string.IsNullOrWhiteSpace(incomingPreferences))
            {
                try
                {
                    using var doc = JsonDocument.Parse(incomingPreferences);
                    if (doc.RootElement.ValueKind == JsonValueKind.Object)
                    {
                        foreach (var prop in doc.RootElement.EnumerateObject())
                        {
                            dict[prop.Name] = prop.Value.Clone();
                        }
                    }
                    else
                    {
                        dict["eatingPreferences"] = doc.RootElement.Clone();
                    }
                }
                catch (JsonException)
                {
                    dict["eatingPreferences"] = JsonSerializer.SerializeToElement(
                        incomingPreferences.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
                }
            }

            if (allergiesAcknowledged == true)
            {
                dict[AllergiesAcknowledgedKey] = JsonSerializer.SerializeToElement(true);
            }
            else if (allergiesAcknowledged == false)
            {
                dict.Remove(AllergiesAcknowledgedKey);
            }

            UpsertString(dict, VietnamRegionKey, vietnamRegion);
            UpsertString(dict, MealContextKey, mealContext);
            if (budgetPerMealVnd.HasValue)
            {
                dict[BudgetPerMealVndKey] = JsonSerializer.SerializeToElement(budgetPerMealVnd.Value);
            }
            UpsertFlexibleJson(dict, PreferredPortionUnitsKey, preferredPortionUnits);

            return JsonSerializer.Serialize(dict);
        }

        public static string? TryGetVietnamRegion(string? preferencesJson) => TryGetString(preferencesJson, VietnamRegionKey);

        public static string? TryGetMealContext(string? preferencesJson) => TryGetString(preferencesJson, MealContextKey);

        public static int? TryGetBudgetPerMealVnd(string? preferencesJson)
        {
            if (!TryGetProperty(preferencesJson, BudgetPerMealVndKey, out var prop))
            {
                return null;
            }

            return prop.ValueKind == JsonValueKind.Number && prop.TryGetInt32(out var value)
                ? value
                : null;
        }

        public static string? TryGetPreferredPortionUnits(string? preferencesJson)
        {
            if (!TryGetProperty(preferencesJson, PreferredPortionUnitsKey, out var prop))
            {
                return null;
            }

            return prop.ValueKind == JsonValueKind.String
                ? prop.GetString()
                : prop.GetRawText();
        }

        public static bool HasMeaningfulAiProfile(string? preferences, string? eatingPattern, string? dislikedFoods)
        {
            if (!string.IsNullOrWhiteSpace(eatingPattern) || !string.IsNullOrWhiteSpace(dislikedFoods))
            {
                return true;
            }

            if (string.IsNullOrWhiteSpace(preferences))
            {
                return false;
            }

            try
            {
                using var doc = JsonDocument.Parse(preferences);
                if (doc.RootElement.ValueKind != JsonValueKind.Object)
                {
                    return true;
                }

                foreach (var prop in doc.RootElement.EnumerateObject())
                {
                    if (prop.Name.Equals(AllergiesAcknowledgedKey, StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    return true;
                }
            }
            catch (JsonException)
            {
                return true;
            }

            return TryGetAllergiesAcknowledged(preferences);
        }

        private static void UpsertString(Dictionary<string, JsonElement> dict, string key, string? value)
        {
            if (value == null)
            {
                return;
            }

            var normalized = value.Trim();
            if (normalized.Length == 0)
            {
                dict.Remove(key);
                return;
            }

            dict[key] = JsonSerializer.SerializeToElement(normalized);
        }

        private static void UpsertFlexibleJson(Dictionary<string, JsonElement> dict, string key, string? value)
        {
            if (value == null)
            {
                return;
            }

            var normalized = value.Trim();
            if (normalized.Length == 0)
            {
                dict.Remove(key);
                return;
            }

            try
            {
                using var doc = JsonDocument.Parse(normalized);
                dict[key] = doc.RootElement.Clone();
            }
            catch (JsonException)
            {
                dict[key] = JsonSerializer.SerializeToElement(
                    normalized.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
            }
        }

        private static string? TryGetString(string? preferencesJson, string key)
        {
            if (!TryGetProperty(preferencesJson, key, out var prop))
            {
                return null;
            }

            return prop.ValueKind == JsonValueKind.String ? prop.GetString() : prop.GetRawText();
        }

        private static bool TryGetProperty(string? preferencesJson, string key, out JsonElement property)
        {
            property = default;
            if (string.IsNullOrWhiteSpace(preferencesJson))
            {
                return false;
            }

            try
            {
                using var doc = JsonDocument.Parse(preferencesJson);
                if (doc.RootElement.ValueKind != JsonValueKind.Object ||
                    !doc.RootElement.TryGetProperty(key, out var prop))
                {
                    return false;
                }

                property = prop.Clone();
                return true;
            }
            catch (JsonException)
            {
                return false;
            }
        }
    }
}
