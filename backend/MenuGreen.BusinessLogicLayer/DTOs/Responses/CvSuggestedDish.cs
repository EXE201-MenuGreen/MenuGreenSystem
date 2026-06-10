using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CvSuggestedDish
    {
        [JsonPropertyName("id_mon_an_goi_y")]
        public string IdMonAnGoiY { get; set; } = string.Empty;

        [JsonPropertyName("ten_mon_an")]
        public string TenMonAn { get; set; } = string.Empty;

        [JsonPropertyName("ten_mon_an_ky_thuat")]
        public string? TenMonAnKyThuat { get; set; }

        [JsonPropertyName("mo_ta_ngan")]
        public string MoTaNgan { get; set; } = string.Empty;

        [JsonPropertyName("do_kha_thi")]
        public string DoKhaThi { get; set; } = string.Empty;

        [JsonPropertyName("confidence")]
        public double Confidence { get; set; }

        [JsonPropertyName("nguyen_lieu_su_dung")]
        public List<CvRecipeIngredient> NguyenLieuSuDung { get; set; } = new();

        [JsonPropertyName("thong_tin_dinh_duong_mon_an")]
        public CvNutritionInfo ThongTinDinhDuongMonAn { get; set; } = new();

        // C# Business Logic Extension Fields
        [JsonPropertyName("is_safe_for_user")]
        public bool IsSafeForUser { get; set; } = true;

        [JsonPropertyName("matched_allergens")]
        public List<string> MatchedAllergens { get; set; } = new();
    }
}
