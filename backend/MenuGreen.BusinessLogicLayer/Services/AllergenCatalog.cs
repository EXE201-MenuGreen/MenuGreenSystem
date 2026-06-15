using System;
using System.Collections.Generic;
using System.Linq;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <summary>Mã dị ứng chuẩn + alias tiếng Việt/Anh (onboarding Flutter + seed).</summary>
    public static class AllergenCatalog
    {
        public const string RiskNone = "none";
        public const string RiskCaution = "caution";
        public const string RiskHigh = "high";

        public const string ModeWarn = "warn";
        public const string ModeHide = "hide";
        public const string ModeAll = "all";

        private static readonly Dictionary<string, string> DisplayNamesVi = new(StringComparer.OrdinalIgnoreCase)
        {
            ["seafood"] = "Hải sản",
            ["peanut"] = "Đậu phộng",
            ["dairy"] = "Sữa",
            ["gluten"] = "Gluten",
            ["egg"] = "Trứng",
            ["soy"] = "Đậu nành",
            ["wheat"] = "Lúa mì",
            ["tree_nut"] = "Hạt cây",
        };

        private static readonly Dictionary<string, HashSet<string>> Aliases = BuildAliases();

        public static IReadOnlyList<string> AllKeys => DisplayNamesVi.Keys.OrderBy(k => k).ToList();

        public static string? NormalizeToKey(string? rawName)
        {
            if (string.IsNullOrWhiteSpace(rawName)) return null;
            var trimmed = rawName.Trim();
            if (DisplayNamesVi.ContainsKey(trimmed)) return trimmed.ToLowerInvariant();

            var folded = Fold(trimmed);
            foreach (var (key, aliases) in Aliases)
            {
                if (aliases.Contains(folded)) return key;
            }

            // Fallback: So khớp mềm nếu tên chứa bất kỳ alias nào (độ dài >= 2)
            foreach (var (key, aliases) in Aliases)
            {
                foreach (var alias in aliases)
                {
                    if (alias.Length >= 2 && folded.Contains(alias, StringComparison.Ordinal))
                        return key;
                }
            }

            return null;
        }

        public static string GetDisplayNameVi(string allergenKey)
        {
            return DisplayNamesVi.TryGetValue(allergenKey, out var name)
                ? name
                : allergenKey;
        }

        public static IReadOnlyList<string> ToDisplayNamesVi(IEnumerable<string> keys)
        {
            return keys.Select(GetDisplayNameVi).Distinct(StringComparer.OrdinalIgnoreCase).ToList();
        }

        public static string ComputeRiskLevel(bool hasMatch)
        {
            return hasMatch ? RiskHigh : RiskNone;
        }

        public static bool IsSafeForUser(string riskLevel) => riskLevel == RiskNone;

        /// <summary>Heuristic: tên nguyên liệu/món có chứa alias của dị ứng user.</summary>
        public static HashSet<string> MatchUserKeysInTexts(IEnumerable<string> texts, HashSet<string> userKeys)
        {
            var matched = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (userKeys.Count == 0) return matched;

            var textList = texts.Where(t => !string.IsNullOrWhiteSpace(t)).Select(Fold).ToList();
            foreach (var userKey in userKeys)
            {
                if (!Aliases.TryGetValue(userKey, out var terms))
                    terms = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { Fold(GetDisplayNameVi(userKey)) };

                foreach (var foldedText in textList)
                {
                    foreach (var term in terms)
                    {
                        if (term.Length >= 2 && foldedText.Contains(term, StringComparison.Ordinal))
                            matched.Add(userKey);
                    }
                }
            }

            return matched;
        }

        private static Dictionary<string, HashSet<string>> BuildAliases()
        {
            var map = new Dictionary<string, HashSet<string>>(StringComparer.OrdinalIgnoreCase);

            void Add(string key, params string[] names)
            {
                if (!map.ContainsKey(key))
                    map[key] = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var n in names)
                    map[key].Add(Fold(n));
            }

            Add("seafood", "hải sản", "hai san", "seafood", "tôm", "cá", "shellfish");
            Add("peanut", "đậu phộng", "dau phong", "peanut", "đậu phụng");
            Add("dairy", "sữa", "sua", "dairy", "lactose", "milk", "phô mai");
            Add("gluten", "gluten", "glutenin");
            Add("egg", "trứng", "trung", "egg", "eggs");
            Add("soy", "đậu nành", "dau nanh", "soy", "soya");
            Add("wheat", "lúa mì", "lua mi", "wheat", "mì", "mi");
            Add("tree_nut", "hạt cây", "hat cay", "tree nut", "tree_nut", "hạnh nhân", "óc chó");

            return map;
        }

        private static string Fold(string value)
        {
            return value.Trim().ToLowerInvariant();
        }
    }
}
