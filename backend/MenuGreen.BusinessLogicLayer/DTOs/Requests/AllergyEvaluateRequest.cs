using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AllergyEvaluateRequest
    {
        public Guid? FoodId { get; set; }
        public List<string>? IngredientNamesVi { get; set; }
    }
}
