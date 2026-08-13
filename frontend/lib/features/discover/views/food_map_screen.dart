import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../models/food_models.dart';
import '../repositories/food_discovery_repository.dart';
import 'favorites_screen.dart';

class MapFoodPin {
  MapFoodPin({
    required this.id,
    required this.name,
    required this.address,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    required this.isSafe,
    required this.mealType,
    required this.icon,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String address;
  final int caloriesKcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int distanceMeters;
  final double latitude;
  final double longitude;
  final bool isSafe;
  final String mealType;
  final IconData icon;
  bool isFavorite;

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '$distanceMeters m';
    }
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    return '$km km';
  }

  LatLng get latLng => LatLng(latitude, longitude);
}

class FoodMapScreen extends StatefulWidget {
  const FoodMapScreen({super.key, this.initialKeyword});

  final String? initialKeyword;

  @override
  State<FoodMapScreen> createState() => _FoodMapScreenState();
}

class _FoodMapScreenState extends State<FoodMapScreen> {
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();

  Position? _currentPosition;
  String _addressText = 'Đang xác định vị trí...';

  int _selectedRadiusMeters = 3000; // Default 3km
  String _selectedMealType = 'ALL';
  String _searchQuery = '';
  MapFoodPin? _selectedPin;

  List<MapFoodPin> _allPins = [];
  final Set<String> _favoritePinIds = {};

  StreamSubscription<Position>? _positionSubscription;
  bool _userMovedMapManually = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      _searchController.text = widget.initialKeyword!;
      _searchQuery = widget.initialKeyword!;
    }
    _loadFavoritesFromRepo();
    _startLocationTracking();
  }

  Future<void> _loadFavoritesFromRepo() async {
    try {
      final favs = await FoodDiscoveryRepository().getFavorites();
      if (!mounted) return;
      setState(() {
        for (final item in favs) {
          _favoritePinIds.add(item.foodId);
        }
        for (final pin in _allPins) {
          if (_favoritePinIds.contains(pin.id)) {
            pin.isFavorite = true;
          }
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    setState(() => _userMovedMapManually = false);
    await _startLocationTracking();
    if (_currentPosition != null && mounted) {
      final isCaliforniaEmulator =
          (_currentPosition!.latitude >= 37.40 &&
              _currentPosition!.latitude <= 37.45) &&
          (_currentPosition!.longitude >= -122.10 &&
              _currentPosition!.longitude <= -122.05);
      final target = isCaliforniaEmulator
          ? const LatLng(10.7769, 106.7009)
          : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _mapController.move(target, 15.0);
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation('Dịch vụ vị trí bị tắt.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation('Chưa cấp quyền vị trí.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation('Quyền vị trí bị từ chối vĩnh viễn.');
        return;
      }

      // 1. Get initial quick position
      try {
        final initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
        _onNewLocationReceived(initialPos, isInitial: true);
      } catch (_) {}

      // 2. Start continuous real-time position stream
      _positionSubscription?.cancel();
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((Position pos) {
            _onNewLocationReceived(pos, isInitial: false);
          });
    } catch (_) {
      _useFallbackLocation('Không thể xác định vị trí.');
    }
  }

  void _onNewLocationReceived(Position pos, {required bool isInitial}) async {
    if (!mounted) return;

    // Detect Android Emulator default virtual location (Mountain View, California)
    final isCaliforniaEmulator =
        (pos.latitude >= 37.40 && pos.latitude <= 37.45) &&
        (pos.longitude >= -122.10 && pos.longitude <= -122.05);

    final double targetLat = isCaliforniaEmulator ? 10.7769 : pos.latitude;
    final double targetLng = isCaliforniaEmulator ? 106.7009 : pos.longitude;

    setState(() {
      _currentPosition = pos;
      _addressText = 'Đang xác định địa chỉ...';
    });

    _generateNearbyFoodPins(targetLat, targetLng);

    if (isInitial || !_userMovedMapManually) {
      _mapController.move(LatLng(targetLat, targetLng), 15.0);
    }

    final resolvedAddress = isCaliforniaEmulator
        ? 'Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh'
        : await _fetchAddressFromCoordinates(targetLat, targetLng);

    if (mounted) {
      setState(() {
        _addressText = resolvedAddress;
      });
    }
  }

  Future<void> _searchLocationByName(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$encoded&countrycodes=vn&limit=1&accept-language=vi',
      );
      final response = await http
          .get(
            uri,
            headers: {'User-Agent': 'MenuGreenApp/1.0 (contact@menugreen.com)'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final first = results[0];
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lng = double.tryParse(first['lon']?.toString() ?? '');
          final displayName = first['display_name']?.toString() ?? query;

          if (lat != null && lng != null && mounted) {
            _userMovedMapManually = true;
            _generateNearbyFoodPins(lat, lng);
            _mapController.move(LatLng(lat, lng), 15.0);

            final parts = displayName
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
            final shortAddress = parts.length > 3
                ? parts.take(3).join(', ')
                : displayName;

            setState(() {
              _addressText = shortAddress;
            });
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<String> _fetchAddressFromCoordinates(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&accept-language=vi&zoom=18',
      );
      final response = await http
          .get(
            uri,
            headers: {'User-Agent': 'MenuGreenApp/1.0 (contact@menugreen.com)'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final address = data['address'];
          if (address is Map<String, dynamic>) {
            final road =
                (address['road'] ??
                        address['pedestrian'] ??
                        address['street'] ??
                        address['path'] ??
                        '')
                    .toString()
                    .trim();
            final ward =
                (address['suburb'] ??
                        address['quarter'] ??
                        address['neighbourhood'] ??
                        address['village'] ??
                        address['residential'] ??
                        '')
                    .toString()
                    .trim();
            final district =
                (address['city_district'] ??
                        address['district'] ??
                        address['county'] ??
                        address['town'] ??
                        address['city'] ??
                        '')
                    .toString()
                    .trim();
            final city = (address['state'] ?? address['province'] ?? '')
                .toString()
                .trim();

            final parts = <String>[];
            if (road.isNotEmpty) {
              parts.add(road);
            }
            if (ward.isNotEmpty && !parts.contains(ward)) {
              parts.add(ward);
            }
            if (district.isNotEmpty && !parts.contains(district)) {
              parts.add(district);
            }
            if (city.isNotEmpty &&
                !parts.contains(city) &&
                !district.contains(city)) {
              parts.add(city);
            }

            if (parts.isNotEmpty) {
              return parts.join(', ');
            }
          }
        }
      }
    } catch (_) {}

    return _resolveFallbackDistrict(lat, lng);
  }

  String _resolveFallbackDistrict(double lat, double lng) {
    if (lat >= 10.83 && lat <= 10.86 && lng >= 106.77 && lng <= 106.80) {
      return 'Lê Văn Việt, Phường Tăng Nhơn Phú, Thành phố Thủ Đức';
    }

    if (lat >= 10.74 && lat <= 10.92 && lng >= 106.70 && lng <= 106.88) {
      if (lat >= 10.86 && lng >= 106.77) {
        return 'Linh Trung, Phường Linh Trung, Thành phố Thủ Đức';
      }
      if (lat >= 10.83 && lng >= 106.75) {
        return 'Võ Văn Ngân, Phường Bình Thọ, Thành phố Thủ Đức';
      }
      if (lat >= 10.79 && lng >= 106.72) {
        return 'Phường Thảo Điền, Thành phố Thủ Đức';
      }
      return 'Lê Văn Việt, Phường Tăng Nhơn Phú, Thành phố Thủ Đức';
    }

    if (lat >= 10.76 && lat <= 10.79 && lng >= 106.68 && lng <= 106.71) {
      if (lat >= 10.773 && lng >= 106.698) {
        return 'Đường Lê Thánh Tôn, Phường Bến Nghé, Quận 1';
      }
      return 'Đường Nguyễn Huệ, Phường Bến Nghé, Quận 1';
    }

    if (lat >= 10.78 && lat <= 10.83 && lng >= 106.68 && lng <= 106.72) {
      return 'Phường 25, Quận Bình Thạnh, TP. Hồ Chí Minh';
    }

    if (lat >= 20.5 && lat <= 21.5 && lng >= 105.3 && lng <= 106.3) {
      return 'Phường Hàng Bạc, Quận Hoàn Kiếm, Hà Nội';
    }

    return 'Tọa độ GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  void _useFallbackLocation(String msg) {
    if (!mounted) return;
    final fallbackPos = Position(
      latitude: 10.7769,
      longitude: 106.7009,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    setState(() {
      _currentPosition = fallbackPos;
      _addressText = 'Chưa xác định được GPS';
    });
    _generateNearbyFoodPins(fallbackPos.latitude, fallbackPos.longitude);
    _mapController.move(const LatLng(10.7769, 106.7009), 14.5);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _generateNearbyFoodPins(double lat, double lng) {
    final isThuDucOrQ9 =
        lat >= 10.74 && lat <= 10.92 && lng >= 106.70 && lng <= 106.88;
    final isHanoi = lat >= 20.5 && lat <= 21.5 && lng >= 105.3 && lng <= 106.3;

    final seedData = isThuDucOrQ9
        ? [
            (
              name: 'Quán Lemon - Healthy & Drinks',
              calories: 280,
              p: 28,
              c: 22,
              f: 8,
              meal: 'LUNCH',
              icon: Icons.eco_rounded,
              dist: 50,
              address: 'Quán Lemon, Đường Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Phở Bò Nam Định - Lê Văn Việt',
              calories: 450,
              p: 26,
              c: 55,
              f: 12,
              meal: 'BREAKFAST',
              icon: Icons.ramen_dining_rounded,
              dist: 180,
              address: '124 Lê Văn Việt, Phường Hiệp Phú, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Cơm Tấm Sườn Bì Chả Vincom Q9',
              calories: 620,
              p: 34,
              c: 72,
              f: 22,
              meal: 'LUNCH',
              icon: Icons.rice_bowl_rounded,
              dist: 320,
              address: 'Vincom Plaza Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Hủ Tiếu Nam Vang Thành Đạt',
              calories: 510,
              p: 28,
              c: 60,
              f: 16,
              meal: 'LUNCH',
              icon: Icons.soup_kitchen_rounded,
              dist: 450,
              address: '215 Lê Văn Việt, Tăng Nhơn Phú A, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Salad Ức Gà Sốt Chanh Lemon',
              calories: 240,
              p: 36,
              c: 10,
              f: 5,
              meal: 'LUNCH',
              icon: Icons.eco_rounded,
              dist: 80,
              address: 'Quán Lemon, Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Nước Ép Trái Cây Lemon',
              calories: 120,
              p: 2,
              c: 28,
              f: 0,
              meal: 'SNACK',
              icon: Icons.local_cafe_rounded,
              dist: 60,
              address: 'Quán Lemon, Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Bánh Mì Thịt Nướng Healthy',
              calories: 420,
              p: 22,
              c: 48,
              f: 14,
              meal: 'BREAKFAST',
              icon: Icons.bakery_dining_rounded,
              dist: 250,
              address: '88 Lê Văn Việt, Phường Hiệp Phú, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Gỏi Cuốn Tôm Thịt Q9',
              calories: 190,
              p: 14,
              c: 22,
              f: 5,
              meal: 'SNACK',
              icon: Icons.tapas_rounded,
              dist: 600,
              address: '300 Lê Văn Việt, Tăng Nhơn Phú A, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Bún Mắm Miền Tây Ngã 4 Thủ Đức',
              calories: 480,
              p: 25,
              c: 58,
              f: 15,
              meal: 'DINNER',
              icon: Icons.set_meal_rounded,
              dist: 850,
              address: 'Ngã 4 Thủ Đức, Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Chè Hạt Sen Tuyết Yến Lemon',
              calories: 160,
              p: 4,
              c: 34,
              f: 2,
              meal: 'SNACK',
              icon: Icons.icecream_rounded,
              dist: 70,
              address: 'Quán Lemon, Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Bún Riêu Cua Đồng Lê Văn Việt',
              calories: 420,
              p: 20,
              c: 48,
              f: 14,
              meal: 'LUNCH',
              icon: Icons.soup_kitchen_rounded,
              dist: 720,
              address: '180 Lê Văn Việt, Quận 9, TP. Thủ Đức',
            ),
            (
              name: 'Cháo Gà Hạt Sen Q9',
              calories: 290,
              p: 18,
              c: 36,
              f: 7,
              meal: 'BREAKFAST',
              icon: Icons.soup_kitchen_rounded,
              dist: 980,
              address: '450 Lê Văn Việt, Tăng Nhơn Phú A, Quận 9, TP. Thủ Đức',
            ),
          ]
        : isHanoi
        ? [
            (
              name: 'Phở Bò Gia Truyền',
              calories: 450,
              p: 25,
              c: 55,
              f: 12,
              meal: 'BREAKFAST',
              icon: Icons.ramen_dining_rounded,
              dist: 220,
              address: '45 Hàng Bạc, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Cơm Tấm Sườn Nướng',
              calories: 620,
              p: 32,
              c: 70,
              f: 22,
              meal: 'LUNCH',
              icon: Icons.rice_bowl_rounded,
              dist: 380,
              address: '12 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Bún Chả Hà Nội',
              calories: 510,
              p: 28,
              c: 60,
              f: 16,
              meal: 'LUNCH',
              icon: Icons.set_meal_rounded,
              dist: 520,
              address: '24 Đinh Tiên Hoàng, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Hủ Tiếu Nam Vang',
              calories: 420,
              p: 22,
              c: 50,
              f: 14,
              meal: 'DINNER',
              icon: Icons.soup_kitchen_rounded,
              dist: 750,
              address: '88 Tràng Thi, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Bánh Mì Thịt Nướng',
              calories: 380,
              p: 18,
              c: 45,
              f: 12,
              meal: 'BREAKFAST',
              icon: Icons.bakery_dining_rounded,
              dist: 180,
              address: '15 Phố Cổ, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Gỏi Cuốn Tôm Thịt',
              calories: 190,
              p: 14,
              c: 22,
              f: 5,
              meal: 'SNACK',
              icon: Icons.tapas_rounded,
              dist: 950,
              address: '30 Hai Bà Trưng, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Mì Quảng Gà Đặc Sản',
              calories: 480,
              p: 26,
              c: 58,
              f: 15,
              meal: 'LUNCH',
              icon: Icons.dinner_dining_rounded,
              dist: 1400,
              address: '102 Bà Triệu, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Nem Nướng Nha Trang',
              calories: 340,
              p: 20,
              c: 38,
              f: 11,
              meal: 'DINNER',
              icon: Icons.kebab_dining_rounded,
              dist: 2100,
              address: '150 Phố Huế, Hà Nội',
            ),
            (
              name: 'Cơm Rang Dưa Bò',
              calories: 580,
              p: 30,
              c: 68,
              f: 18,
              meal: 'DINNER',
              icon: Icons.rice_bowl_rounded,
              dist: 2800,
              address: '200 Trần Khát Chân, Hà Nội',
            ),
            (
              name: 'Chè Hạt Sen Long Nhãn',
              calories: 160,
              p: 4,
              c: 34,
              f: 2,
              meal: 'SNACK',
              icon: Icons.icecream_rounded,
              dist: 420,
              address: '18 Hàng Gai, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Cháo Gà Hạt Sen',
              calories: 290,
              p: 18,
              c: 36,
              f: 7,
              meal: 'BREAKFAST',
              icon: Icons.soup_kitchen_rounded,
              dist: 1100,
              address: '55 Hàng Đường, Hoàn Kiếm, Hà Nội',
            ),
            (
              name: 'Salad Ức Gà Sốt Chanh',
              calories: 260,
              p: 35,
              c: 12,
              f: 6,
              meal: 'LUNCH',
              icon: Icons.eco_rounded,
              dist: 1600,
              address: '72 Trần Hưng Đạo, Hà Nội',
            ),
          ]
        : [
            (
              name: 'Cơm Tấm Sườn Bì Chả',
              calories: 620,
              p: 34,
              c: 72,
              f: 22,
              meal: 'LUNCH',
              icon: Icons.rice_bowl_rounded,
              dist: 220,
              address: '45 Nguyễn Trãi, Quận 1, TP.HCM',
            ),
            (
              name: 'Phở Bò Nam Định',
              calories: 450,
              p: 26,
              c: 55,
              f: 12,
              meal: 'BREAKFAST',
              icon: Icons.ramen_dining_rounded,
              dist: 380,
              address: '12 Nguyễn Thị Minh Khai, Quận 1, TP.HCM',
            ),
            (
              name: 'Hủ Tiếu Nam Vang Thành Đạt',
              calories: 510,
              p: 28,
              c: 60,
              f: 16,
              meal: 'LUNCH',
              icon: Icons.soup_kitchen_rounded,
              dist: 520,
              address: '34 Cô Giang, Quận 1, TP.HCM',
            ),
            (
              name: 'Bánh Mì Huỳnh Hoa',
              calories: 540,
              p: 24,
              c: 52,
              f: 20,
              meal: 'BREAKFAST',
              icon: Icons.bakery_dining_rounded,
              dist: 180,
              address: '26 Lê Thị Riêng, Quận 1, TP.HCM',
            ),
            (
              name: 'Gỏi Cuốn Tôm Thịt',
              calories: 190,
              p: 14,
              c: 22,
              f: 5,
              meal: 'SNACK',
              icon: Icons.tapas_rounded,
              dist: 420,
              address: '15 Phạm Ngọc Thạch, Quận 3, TP.HCM',
            ),
            (
              name: 'Bún Mắm Miền Tây',
              calories: 480,
              p: 25,
              c: 58,
              f: 15,
              meal: 'DINNER',
              icon: Icons.set_meal_rounded,
              dist: 750,
              address: '88 Nguyễn Tri Phương, Quận 10, TP.HCM',
            ),
            (
              name: 'Lẩu Mắm Sài Gòn',
              calories: 580,
              p: 32,
              c: 60,
              f: 22,
              meal: 'DINNER',
              icon: Icons.dinner_dining_rounded,
              dist: 1200,
              address: '102 Lý Chính Thắng, Quận 3, TP.HCM',
            ),
            (
              name: 'Bún Riêu Cua Đồng',
              calories: 420,
              p: 20,
              c: 48,
              f: 14,
              meal: 'LUNCH',
              icon: Icons.soup_kitchen_rounded,
              dist: 950,
              address: '55 Võ Văn Tần, Quận 3, TP.HCM',
            ),
            (
              name: 'Chè Thái Sài Gòn',
              calories: 220,
              p: 4,
              c: 42,
              f: 6,
              meal: 'SNACK',
              icon: Icons.icecream_rounded,
              dist: 600,
              address: '18 Nguyễn Tri Phương, Quận 10, TP.HCM',
            ),
            (
              name: 'Salad Ức Gà Sốt Chanh',
              calories: 260,
              p: 35,
              c: 12,
              f: 6,
              meal: 'LUNCH',
              icon: Icons.eco_rounded,
              dist: 1400,
              address: '72 Lê Thánh Tôn, Quận 1, TP.HCM',
            ),
            (
              name: 'Bánh Xèo Miền Tây',
              calories: 460,
              p: 22,
              c: 50,
              f: 18,
              meal: 'DINNER',
              icon: Icons.kebab_dining_rounded,
              dist: 1800,
              address: '150 Đinh Tiên Hoàng, Quận 1, TP.HCM',
            ),
            (
              name: 'Cháo Lòng Đêm',
              calories: 380,
              p: 24,
              c: 40,
              f: 14,
              meal: 'DINNER',
              icon: Icons.ramen_dining_rounded,
              dist: 2100,
              address: '200 Hai Bà Trưng, Quận 1, TP.HCM',
            ),
          ];

    final List<MapFoodPin> pins = [];

    for (int i = 0; i < seedData.length; i++) {
      final item = seedData[i];
      final angle = (i * (360 / seedData.length)) * (math.pi / 180);
      final radiusKm = item.dist / 1000.0;
      final latOffset = (radiusKm / 111.0) * math.cos(angle);
      final lngOffset =
          (radiusKm / (111.0 * math.cos(lat * math.pi / 180))) *
          math.sin(angle);

      pins.add(
        MapFoodPin(
          id: 'pin_$i',
          name: item.name,
          address: item.address,
          caloriesKcal: item.calories,
          proteinG: item.p,
          carbsG: item.c,
          fatG: item.f,
          distanceMeters: item.dist,
          latitude: lat + latOffset,
          longitude: lng + lngOffset,
          isSafe: i % 5 != 0,
          mealType: item.meal,
          icon: item.icon,
        ),
      );
    }

    setState(() {
      _allPins = pins;
      if (_allPins.isNotEmpty) _selectedPin = _allPins.first;
    });
  }

  List<MapFoodPin> get _filteredPins {
    return _allPins.where((pin) {
      if (pin.distanceMeters > _selectedRadiusMeters) return false;
      if (_selectedMealType != 'ALL' && pin.mealType != _selectedMealType) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = pin.name.toLowerCase().contains(query);
        final addrMatch = pin.address.toLowerCase().contains(query);
        if (!nameMatch && !addrMatch) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _toggleFavoritePin(MapFoodPin pin) async {
    if (pin.id.startsWith('pin_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'M\u00f3n tr\u00ean b\u1ea3n \u0111\u1ed3 ch\u01b0a thu\u1ed9c Food Catalog n\u00ean kh\u00f4ng th\u1ec3 l\u01b0u v\u00e0o m\u00f3n y\u00eau th\u00edch.',
          ),
        ),
      );
      return;
    }
    final repo = FoodDiscoveryRepository();
    final isCurrentlyFav = _favoritePinIds.contains(pin.id);

    setState(() {
      if (isCurrentlyFav) {
        _favoritePinIds.remove(pin.id);
        pin.isFavorite = false;
      } else {
        _favoritePinIds.add(pin.id);
        pin.isFavorite = true;
      }
    });

    if (!isCurrentlyFav) {
      await repo.saveFavoriteItem(
        FavoriteFoodItem(
          foodId: pin.id,
          nameVi: pin.name,
          caloriesKcal: pin.caloriesKcal.toDouble(),
        ),
      );
    } else {
      await repo.removeFavorite(pin.id);
    }

    final isFav = _favoritePinIds.contains(pin.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? '❤️ Đã lưu "${pin.name}" tại "${pin.address}" vào Yêu thích!'
              : '💔 Đã xóa "${pin.name}" khỏi danh sách Yêu thích.',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Xem Yêu Thích',
          textColor: Colors.amber,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showVenueDishesModal(MapFoodPin venuePin) {
    final venueDishes = _allPins
        .where((p) => (p.latitude - venuePin.latitude).abs() < 0.005)
        .toList();
    if (venueDishes.isEmpty) {
      venueDishes.add(venuePin);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venuePin.name,
                              style: beVietnamPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '📍 ${venuePin.address}',
                              style: beVietnamPro(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  Text(
                    'Thực đơn món ăn tại địa điểm này (${venueDishes.length} món)',
                    style: beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.separated(
                      itemCount: venueDishes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final dish = venueDishes[idx];
                        final isFav = _favoritePinIds.contains(dish.id);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                dish.icon,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dish.name,
                                      style: beVietnamPro(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dish.caloriesKcal} kcal • P:${dish.proteinG}g C:${dish.carbsG}g F:${dish.fatG}g',
                                      style: beVietnamPro(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav ? Colors.red : Colors.grey,
                                  size: 22,
                                ),
                                onPressed: () {
                                  _toggleFavoritePin(dish);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFavoritesModal() {
    final favList = _allPins
        .where((p) => _favoritePinIds.contains(p.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Món ăn yêu thích kèm địa điểm',
                        style: beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),

                  if (favList.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite_border_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có món ăn nào trong danh sách Yêu thích.',
                              style: beVietnamPro(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: favList.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final dish = favList[idx];

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  dish.icon,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dish.name,
                                        style: beVietnamPro(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '📍 ${dish.address}',
                                        style: beVietnamPro(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${dish.caloriesKcal} kcal • P:${dish.proteinG}g C:${dish.carbsG}g F:${dish.fatG}g',
                                        style: beVietnamPro(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() => _selectedPin = dish);
                                    _mapController.move(dish.latLng, 16.5);
                                  },
                                  child: const Text('Định vị'),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _toggleFavoritePin(dish);
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCaliforniaEmulator =
        _currentPosition != null &&
        (_currentPosition!.latitude >= 37.40 &&
            _currentPosition!.latitude <= 37.45) &&
        (_currentPosition!.longitude >= -122.10 &&
            _currentPosition!.longitude <= -122.05);

    final centerLatLng = _currentPosition != null
        ? (isCaliforniaEmulator
              ? const LatLng(10.7769, 106.7009)
              : LatLng(_currentPosition!.latitude, _currentPosition!.longitude))
        : const LatLng(10.7769, 106.7009);

    final pinsToRender = _filteredPins;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Detailed Interactive Map View with OSM / High Resolution Tiles
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerLatLng,
                initialZoom: 14.5,
                minZoom: 5.0,
                maxZoom: 18.0,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    _userMovedMapManually = true;
                  }
                },
                onTap: (tapPosition, point) {
                  setState(() => _selectedPin = null);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.menugreen.app',
                ),
                MarkerLayer(
                  markers: [
                    // Current User GPS Location Marker
                    Marker(
                      point: centerLatLng,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.25),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    // Food Pin Markers
                    ...pinsToRender.map((pin) {
                      final isSelected = _selectedPin?.id == pin.id;
                      return Marker(
                        point: pin.latLng,
                        width: isSelected ? 160 : 130,
                        height: 54,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedPin = pin);
                            _mapController.move(
                              pin.latLng,
                              _mapController.camera.zoom,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  pin.icon,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pin.name,
                                        style: beVietnamPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${pin.caloriesKcal} kcal • ${pin.distanceFormatted}',
                                        style: beVietnamPro(
                                          fontSize: 9.5,
                                          color: isSelected
                                              ? Colors.white70
                                              : AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            // 2. Top Search & Header Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopSearchHeader(),
            ),

            // 3. Filter Bar (Radius & Meal Type)
            Positioned(top: 108, left: 16, right: 16, child: _buildFilterBar()),

            // 4. Zoom & Re-center FABs
            Positioned(
              right: 16,
              bottom: _selectedPin != null ? 240 : 30,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'recenter_fab',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 4,
                    onPressed: () {
                      _userMovedMapManually = false;
                      _startLocationTracking();
                    },
                    child: const Icon(Icons.my_location_rounded),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_fab',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textDark,
                    elevation: 3,
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    child: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(height: 6),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_fab',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textDark,
                    elevation: 3,
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    child: const Icon(Icons.remove_rounded),
                  ),
                ],
              ),
            ),

            // 5. Selected Food Bottom Preview Sheet
            if (_selectedPin != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildSelectedPinCard(_selectedPin!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back Icon | Search Input | Clear | GPS Button
          Row(
            children: [
              IconButton(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: AppColors.textDark,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onSubmitted: (val) => _searchLocationByName(val),
                                      style: beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm món ăn hoặc nhập địa điểm...',
                    hintStyle: beVietnamProHint(
                      fontSize: 13.5,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _searchLocationByName(_searchQuery),
                ),
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ],
              Container(
                height: 18,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
              ),
              InkWell(
                onTap: _determinePosition,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.gps_fixed_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Container(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 6),

          // Row 2: Real-time Location Address Chip
          InkWell(
            onTap: _determinePosition,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _addressText,
                    style: beVietnamPro(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.sync_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Favorite dishes chip
          ActionChip(
            avatar: const Icon(
              Icons.favorite_rounded,
              size: 16,
              color: Colors.red,
            ),
            label: Text(
              'Yêu thích (${_favoritePinIds.length})',
                                      style: beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade800,
              ),
            ),
            backgroundColor: const Color(0xFFFEF2F2),
            side: BorderSide(color: Colors.red.shade200),
            onPressed: _showFavoritesModal,
          ),
          const SizedBox(width: 8),

          // Venue dishes modal chip
          ActionChip(
            avatar: const Icon(
              Icons.storefront_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            label: Text(
              'Món tại quán',
                                      style: beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            backgroundColor: const Color(0xFFF0FDF4),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            onPressed: () {
              if (_selectedPin != null) {
                _showVenueDishesModal(_selectedPin!);
              } else if (_allPins.isNotEmpty) {
                _showVenueDishesModal(_allPins.first);
              }
            },
          ),
          const SizedBox(width: 8),

          // Radius selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                DropdownButton<int>(
                  value: _selectedRadiusMeters,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primary,
                  ),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 500, child: Text('Bán kính 500m')),
                    DropdownMenuItem(value: 1000, child: Text('Bán kính 1 km')),
                    DropdownMenuItem(value: 3000, child: Text('Bán kính 3 km')),
                    DropdownMenuItem(value: 5000, child: Text('Bán kính 5 km')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRadiusMeters = val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Meal filter chips
          _buildMealFilterChip('ALL', 'Tất cả'),
          const SizedBox(width: 6),
          _buildMealFilterChip('BREAKFAST', 'Sáng 🌅'),
          const SizedBox(width: 6),
          _buildMealFilterChip('LUNCH', 'Trưa ☀️'),
          const SizedBox(width: 6),
          _buildMealFilterChip('DINNER', 'Tối 🌙'),
        ],
      ),
    );
  }

  Widget _buildMealFilterChip(String value, String label) {
    final isSelected = _selectedMealType == value;
    return ChoiceChip(
      label: Text(
        label,
                                      style: beVietnamPro(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (sel) {
        if (sel) setState(() => _selectedMealType = value);
      },
    );
  }

  Widget _buildSelectedPinCard(MapFoodPin pin) {
    final isFav = _favoritePinIds.contains(pin.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(pin.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pin.name,
                            style: beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pin.distanceFormatted,
                            style: beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pin.address,
                      style: beVietnamPro(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.red : Colors.grey,
                  size: 24,
                ),
                onPressed: () => _toggleFavoritePin(pin),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => setState(() => _selectedPin = null),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Macro breakdown
          Row(
            children: [
              _buildMacroPill(
                '${pin.caloriesKcal} kcal',
                'Năng lượng',
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildMacroPill(
                '${pin.proteinG}g',
                'Protein',
                const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _buildMacroPill(
                '${pin.carbsG}g',
                'Carbs',
                const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              _buildMacroPill(
                '${pin.fatG}g',
                'Chất béo',
                const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showVenueDishesModal(pin),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Thực đơn quán'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _mapController.move(pin.latLng, 16.5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã định vị chỉ đường tới ${pin.name} (${pin.distanceFormatted}).',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 16),
                  label: const Text('Dẫn đường'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await showMealLogSheet(context, loggedAt: DateTime.now());
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Ghi bữa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
                                      style: beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
                                      style: beVietnamPro(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
