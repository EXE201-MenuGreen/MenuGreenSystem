using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.BusinessLogicLayer.Interfaces;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Services
{
    /// <inheritdoc />
    public class ShoppingTripBuilderService : IShoppingTripBuilderService
    {
        // VN-context weekly stock keywords (lowercase, accent-insensitive enough
        // for the catalog this project ships with). Matches "Gạo", "gao",
        // "Đường", "duong", etc.
        private static readonly string[] StockKeywords =
        {
            "gạo", "gao", "đường", "duong", "muối", "muoi",
            "nước mắm", "nuoc mam", "dầu", "dau", "bột ngọt", "bot ngot",
            "tiêu", "tieu", "ớt khô", "ot kho", "bột canh", "bot canh",
        };

        /// <inheritdoc />
        public Task<List<ShoppingTripResponse>> BuildShoppingTripsAsync(
            IList<MealPlanItem> planItems,
            IList<GroceryListDayResponse> days,
            IDictionary<Guid, Ingredient> ingredientCatalogById)
        {
            // 1. Decide which ingredient ids are "stock" using keyword heuristic.
            var stockIds = new HashSet<Guid>();
            foreach (var (id, ingredient) in ingredientCatalogById)
            {
                if (IsStock(ingredient.NameVi) || IsStock(ingredient.NameEn))
                {
                    stockIds.Add(id);
                }
            }

            // 2. Flatten days into (plannedDate, item) tuples, ignoring empty days.
            var dayItems = days
                .Where(d => d.Items.Count > 0)
                .SelectMany(d => d.Items.Select(item => (d.PlannedDate, item)))
                .ToList();

            // 3. Split into stock vs non-stock lists with their covered meals.
            var stockItems = new List<(GroceryListItemResponse Item, DateOnly PlannedDate, string MealType)>();
            var nonStockItems = new List<(GroceryListItemResponse Item, DateOnly PlannedDate, string MealType)>();
            foreach (var (plannedDate, item) in dayItems)
            {
                var meals = planItems
                    .Where(m => m.PlannedDate == plannedDate)
                    .Select(m => m.MealType ?? string.Empty)
                    .Where(mt => !string.IsNullOrWhiteSpace(mt))
                    .ToList();
                var bucket = stockIds.Contains(item.IngredientId) ? stockItems : nonStockItems;
                bucket.Add((item, plannedDate, meals.FirstOrDefault() ?? string.Empty));
            }

            // 4. InitialTrip = day before earliest plannedDate, contains stock items.
            var result = new List<ShoppingTripResponse>();
            var earliestPlanned = days
                .Where(d => d.Items.Count > 0)
                .Select(d => d.PlannedDate)
                .DefaultIfEmpty(DateOnly.FromDateTime(DateTime.UtcNow))
                .Min();
            var initialTripDate = earliestPlanned.AddDays(-1);

            if (stockItems.Count > 0)
            {
                result.Add(BuildTrip(
                    initialTripDate,
                    isInitial: true,
                    stockItems));
            }

            // 5. Non-stock trips: shopping date = plannedDate - 1.
            //    Merge multiple plan items that share the same shopping date.
            var groupedByShoppingDate = nonStockItems
                .GroupBy(x => x.PlannedDate.AddDays(-1))
                .OrderBy(g => g.Key);

            foreach (var group in groupedByShoppingDate)
            {
                // No need for an extra "InitialTrip" entry here; stock items
                // already cover the bulk-buy case.
                if (stockItems.Count > 0 && group.Key == initialTripDate)
                {
                    // Append non-stock items that also need to be bought the
                    // day before plan start, onto the initial trip.
                    var initialTrip = result.First();
                    MergeInto(initialTrip, group.Select(x => (x.Item, x.PlannedDate, x.MealType)));
                    continue;
                }

                result.Add(BuildTrip(group.Key, isInitial: false, group.ToList()));
            }

            // Stable sort: initial first, then ascending shopping date.
            result = result
                .OrderByDescending(t => t.IsInitialTrip)
                .ThenBy(t => t.ShoppingDate)
                .ToList();

            return Task.FromResult(result);
        }

        private static ShoppingTripResponse BuildTrip(
            DateOnly shoppingDate,
            bool isInitial,
            IList<(GroceryListItemResponse Item, DateOnly PlannedDate, string MealType)> entries)
        {
            var coveredMeals = entries
                .SelectMany(e => string.IsNullOrEmpty(e.MealType)
                    ? Array.Empty<(DateOnly, string)>()
                    : new[] { (e.PlannedDate, e.MealType) })
                .Distinct()
                .OrderBy(t => t.Item1)
                .ThenBy(t => t.Item2)
                .Select(t => new GroceryCoveredMealResponse
                {
                    PlannedDate = t.Item1,
                    MealType = t.Item2,
                })
                .ToList();

            // Aggregate quantities per ingredient + unit within a single trip.
            var items = entries
                .GroupBy(e => new { e.Item.IngredientId, e.Item.Unit })
                .Select(g =>
                {
                    var first = g.First().Item;
                    var isStock = IsStock(first.Name);
                    return new GroceryListItemResponse
                    {
                        IngredientId = first.IngredientId,
                        Name = first.Name,
                        Unit = first.Unit,
                        Quantity = g.Sum(x => x.Item.Quantity),
                        EstimatedPriceVnd = g.Sum(x => x.Item.EstimatedPriceVnd),
                        IsWeeklyStock = isStock,
                    };
                })
                .OrderBy(i => i.Name)
                .ToList();

            return new ShoppingTripResponse
            {
                ShoppingDate = shoppingDate,
                IsInitialTrip = isInitial,
                EstimatedTotalVnd = items.Sum(i => i.EstimatedPriceVnd),
                CoveredMeals = coveredMeals,
                Items = items,
            };
        }

        private static void MergeInto(
            ShoppingTripResponse trip,
            IEnumerable<(GroceryListItemResponse Item, DateOnly PlannedDate, string MealType)> entries)
        {
            foreach (var entry in entries)
            {
                var existing = trip.Items.FirstOrDefault(i =>
                    i.IngredientId == entry.Item.IngredientId && i.Unit == entry.Item.Unit);
                if (existing != null)
                {
                    existing.Quantity += entry.Item.Quantity;
                    existing.EstimatedPriceVnd += entry.Item.EstimatedPriceVnd;
                }
                else
                {
                    var item = entry.Item;
                    item.IsWeeklyStock = IsStock(item.Name);
                    trip.Items.Add(item);
                }
            }

            foreach (var entry in entries.Where(e => !string.IsNullOrEmpty(e.MealType)))
            {
                var covered = new GroceryCoveredMealResponse
                {
                    PlannedDate = entry.PlannedDate,
                    MealType = entry.MealType,
                };
                if (!trip.CoveredMeals.Any(c => c.PlannedDate == covered.PlannedDate
                                                && c.MealType == covered.MealType))
                {
                    trip.CoveredMeals.Add(covered);
                }
            }

            trip.EstimatedTotalVnd = trip.Items.Sum(i => i.EstimatedPriceVnd);
            trip.Items = trip.Items.OrderBy(i => i.Name).ToList();
            trip.CoveredMeals = trip.CoveredMeals
                .OrderBy(c => c.PlannedDate)
                .ThenBy(c => c.MealType)
                .ToList();
        }

        private static bool IsStock(string? name)
        {
            if (string.IsNullOrWhiteSpace(name)) return false;
            var lower = name.ToLowerInvariant();
            return StockKeywords.Any(k => lower.Contains(k));
        }
    }
}
