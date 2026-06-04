using System;
using System.Collections.Generic;
using System.Text.Json;

namespace MenuGreen.BusinessLogicLayer.Services
{
    internal static class UserAiProfilePreferencesHelper
    {
        private const string AllergiesAcknowledgedKey = "allergiesAcknowledged";

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

        public static string MergePreferences(string? existingJson, string? incomingPreferences, bool? allergiesAcknowledged)
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

            return JsonSerializer.Serialize(dict);
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
    }
}
