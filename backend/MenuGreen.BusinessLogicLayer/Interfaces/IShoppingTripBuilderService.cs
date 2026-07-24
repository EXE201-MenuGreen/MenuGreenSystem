using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;
using MenuGreen.DataAccessLayer.Entities;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    /// <summary>
    /// Groups <see cref="GroceryListDayResponse"/> entries into
    /// user-friendly shopping trips (one trip = one chợ visit).
    /// Phase 2 rules:
    /// - Stock items (gạo/đường/muối/...) go to one InitialTrip dated the
    ///   day before the plan starts so user can do a single weekly bulk buy.
    /// - Other items go to a trip dated PlannedDate - 1 (mua sau tan làm
    ///   hôm trước để nấu cho ngày hôm sau).
    /// </summary>
    public interface IShoppingTripBuilderService
    {
        Task<List<ShoppingTripResponse>> BuildShoppingTripsAsync(
            IList<MealPlanItem> planItems,
            IList<GroceryListDayResponse> days,
            IDictionary<Guid, Ingredient> ingredientCatalogById);
    }
}
