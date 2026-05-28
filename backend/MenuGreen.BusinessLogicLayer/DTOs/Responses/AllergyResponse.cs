using System;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class AllergyResponse
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public bool IsActive { get; set; }
    }
}
