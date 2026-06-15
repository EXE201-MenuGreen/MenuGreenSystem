using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class AllergyEvaluateBatchRequest
    {
        [Required]
        public List<Guid> FoodIds { get; set; } = new();
    }
}
