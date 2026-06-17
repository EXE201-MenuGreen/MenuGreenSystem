using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace MenuGreen.BusinessLogicLayer.DTOs.Requests
{
    public class BatchSubstitutionRequest
    {
        [Required]
        public List<Guid> IngredientIds { get; set; } = new();
    }
}
