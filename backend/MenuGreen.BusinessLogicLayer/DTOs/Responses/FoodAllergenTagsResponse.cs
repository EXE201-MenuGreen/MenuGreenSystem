using System;
using System.Collections.Generic;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class FoodAllergenTagsResponse
    {
        public Guid FoodId { get; set; }
        public List<string> AllergenKeys { get; set; } = new();
        public List<string> AllergenLabelsVi { get; set; } = new();
        public List<string> AvailableAllergenKeys { get; set; } = new();
    }
}
