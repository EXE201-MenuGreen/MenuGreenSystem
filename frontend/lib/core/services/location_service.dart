import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class LocationService {
  /// Xác định vị trí tọa độ hiện tại và xin quyền nếu cần
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ định vị đã bật chưa
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // Kiểm tra quyền định vị
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn, vui lòng bật trong cài đặt.');
    }

    // Lấy tọa độ hiện tại với độ chính xác vừa phải để nhanh hơn
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    );
  }

  /// Gọi Goong API Reverse Geocoding để lấy thông tin Tỉnh/Thành phố
  static Future<String?> getProvinceFromCoordinates(double lat, double lng) async {
    try {
      final response = await ApiClient().get(
        ApiEndpoints.locationReverseGeocode(lat, lng),
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data['province']?.toString();
      }
    } catch (_) {
      // Bỏ qua lỗi kết nối
    }
    return null;
  }

  /// Ánh xạ Tỉnh/Thành phố sang vùng miền (north, central, south)
  static String mapProvinceToRegion(String province) {
    final clean = province.toLowerCase()
        .replaceAll('thành phố', '')
        .replaceAll('tỉnh', '')
        .replaceAll('tp.', '')
        .trim();

    final north = [
      'hà nội', 'hải phòng', 'quảng ninh', 'bắc ninh', 'hải dương', 'hưng yên', 
      'nam định', 'ninh bình', 'thái bình', 'vĩnh phúc', 'phú thọ', 'thái nguyên', 
      'bắc giang', 'hòa bình', 'sơn la', 'điện biên', 'lai châu', 'lào cai', 
      'yên bái', 'hà giang', 'tuyên quang', 'cao bằng', 'bắc kạn', 'lạng sơn'
    ];
    final central = [
      'đà nẵng', 'thừa thiên huế', 'huế', 'quảng nam', 'quảng ngãi', 'bình định', 
      'phú yên', 'khánh hòa', 'nha trang', 'ninh thuận', 'bình thuận', 'thanh hóa', 
      'nghệ an', 'hà tĩnh', 'quảng bình', 'quảng trị', 'kon tum', 'gia lai', 
      'đắk lắk', 'đắk nông', 'lâm đồng', 'đà lạt'
    ];
    final south = [
      'hồ chí minh', 'sài gòn', 'bình dương', 'đồng nai', 'bà rịa - vũng tàu', 'vũng tàu', 
      'long an', 'tiền giang', 'bến tre', 'trà vinh', 'vĩnh long', 'đồng tháp', 
      'an giang', 'kiên giang', 'cần thơ', 'hậu giang', 'sóc trăng', 'bạc liêu', 
      'cà mau', 'tây ninh', 'bình phước'
    ];

    if (north.any((p) => clean.contains(p))) return 'north';
    if (central.any((p) => clean.contains(p))) return 'central';
    if (south.any((p) => clean.contains(p))) return 'south';

    // Fallback theo từ khóa
    if (clean.contains('bắc') || clean.contains('hà')) return 'north';
    if (clean.contains('trung') || clean.contains('huế') || clean.contains('đà')) return 'central';
    if (clean.contains('nam') || clean.contains('sài') || clean.contains('mê kông') || clean.contains('mây')) return 'south';

    return 'north'; // Mặc định là miền Bắc
  }

  /// Lấy vùng miền hiện tại dựa trên tọa độ thiết bị
  static Future<String> detectCurrentRegion() async {
    try {
      final position = await getCurrentPosition();
      final province = await getProvinceFromCoordinates(position.latitude, position.longitude);
      if (province == null || province.isEmpty) {
        // Fallback dựa trên tọa độ địa lý thô ở Việt Nam
        if (position.latitude > 16.5) return 'north';
        if (position.latitude < 11.5) return 'south';
        return 'central';
      }
      return mapProvinceToRegion(province);
    } catch (_) {
      // Mặc định trả về miền Bắc nếu có lỗi xảy ra
      return 'north';
    }
  }

  /// Trả về tên hiển thị tiếng Việt của vùng miền
  static String getRegionDisplayName(String region) {
    switch (region.toLowerCase()) {
      case 'north':
      case 'bac':
      case 'bắc':
        return 'Bắc';
      case 'central':
      case 'trung':
      case 'miền trung':
        return 'Trung';
      case 'south':
      case 'nam':
      case 'miền nam':
        return 'Nam';
      default:
        return 'Toàn quốc';
    }
  }
}
