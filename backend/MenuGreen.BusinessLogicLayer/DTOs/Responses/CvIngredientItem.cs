using System.Text.Json.Serialization;

namespace MenuGreen.BusinessLogicLayer.DTOs.Responses
{
    public class CvIngredientItem
    {
        [JsonPropertyName("id_nguyen_lieu")]
        public string IdNguyenLieu { get; set; } = string.Empty;

        [JsonPropertyName("ten_nguyen_lieu")]
        public string TenNguyenLieu { get; set; } = string.Empty;

        [JsonPropertyName("ten_nguyen_lieu_ky_thuat")]
        public string TenNguyenLieuKyThuat { get; set; } = string.Empty;

        [JsonPropertyName("khoi_luong_uoc_tinh_g")]
        public double KhoiLuongUocTinhG { get; set; }

        [JsonPropertyName("do_chinh_xac_uoc_tinh")]
        public string DoChinhXacUocTinh { get; set; } = string.Empty;
    }
}
