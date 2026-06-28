using System;

namespace MenuGreen.DataAccessLayer.Entities
{
    public class DefaultPortionUnit
    {
        public Guid Id { get; set; }
        public string UnitName { get; set; } = string.Empty; // chén, bát, tô, đĩa, muỗng...
        public decimal GramsEquivalent { get; set; }       // Trọng lượng quy đổi gram
        public string Description { get; set; } = string.Empty; // Mô tả đơn vị
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
