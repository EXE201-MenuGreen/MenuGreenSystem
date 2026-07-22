import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../tracking/widgets/meal_log_sheet.dart';

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

  static const LatLng _hanoiCenter = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      _searchController.text = widget.initialKeyword!;
      _searchQuery = widget.initialKeyword!;
    }
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation('Dịch vụ vị trí bị tắt. Sử dụng vị trí mặc định (Hà Nội).');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation('Chưa cấp quyền vị trí. Sử dụng vị trí mặc định.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation('Quyền vị trí bị từ chối vĩnh viễn.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      // Check if location is emulator Mountain View CA (37.42, -122.08) -> use Hanoi center for better Vietnamese food demo
      final isEmulatorDefault = (pos.latitude - 37.42).abs() < 0.1 && (pos.longitude - (-122.08)).abs() < 0.1;
      final targetLat = isEmulatorDefault ? _hanoiCenter.latitude : pos.latitude;
      final targetLng = isEmulatorDefault ? _hanoiCenter.longitude : pos.longitude;

      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _addressText = isEmulatorDefault
            ? 'Quận Hoàn Kiếm, Hà Nội (Vị trí mẫu)'
            : 'Tọa độ: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (GPS)';
      });

      _generateNearbyFoodPins(targetLat, targetLng);
      _mapController.move(LatLng(targetLat, targetLng), 14.5);
    } catch (_) {
      _useFallbackLocation('Sử dụng vị trí mặc định (Hà Nội, Việt Nam).');
    }
  }

  void _useFallbackLocation(String msg) {
    if (!mounted) return;
    final fallbackPos = Position(
      latitude: _hanoiCenter.latitude,
      longitude: _hanoiCenter.longitude,
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
      _addressText = 'Quận Hoàn Kiếm, Hà Nội';
    });
    _generateNearbyFoodPins(fallbackPos.latitude, fallbackPos.longitude);
    _mapController.move(_hanoiCenter, 14.5);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _generateNearbyFoodPins(double lat, double lng) {
    final seedData = [
      (name: 'Phở Bò Gia Truyền', calories: 450, p: 25, c: 55, f: 12, meal: 'BREAKFAST', icon: Icons.ramen_dining_rounded, dist: 220, address: '45 Hàng Bạc, Hoàn Kiếm'),
      (name: 'Cơm Tấm Sườn Nướng', calories: 620, p: 32, c: 70, f: 22, meal: 'LUNCH', icon: Icons.rice_bowl_rounded, dist: 380, address: '12 Lý Thường Kiệt, Hoàn Kiếm'),
      (name: 'Bún Chả Hà Nội', calories: 510, p: 28, c: 60, f: 16, meal: 'LUNCH', icon: Icons.set_meal_rounded, dist: 520, address: '24 Đinh Tiên Hoàng, Hoàn Kiếm'),
      (name: 'Hủ Tiếu Nam Vang', calories: 420, p: 22, c: 50, f: 14, meal: 'DINNER', icon: Icons.soup_kitchen_rounded, dist: 750, address: '88 Tràng Thi, Hoàn Kiếm'),
      (name: 'Bánh Mì Thịt Nướng', calories: 380, p: 18, c: 45, f: 12, meal: 'BREAKFAST', icon: Icons.bakery_dining_rounded, dist: 180, address: '15 Phố Cổ, Hoàn Kiếm'),
      (name: 'Gỏi Cuốn Tôm Thịt', calories: 190, p: 14, c: 22, f: 5, meal: 'SNACK', icon: Icons.tapas_rounded, dist: 950, address: '30 Hai Bà Trưng, Hoàn Kiếm'),
      (name: 'Mì Quảng Gà Đặc Sản', calories: 480, p: 26, c: 58, f: 15, meal: 'LUNCH', icon: Icons.dinner_dining_rounded, dist: 1400, address: '102 Bà Triệu, Hoàn Kiếm'),
      (name: 'Nem Nướng Nha Trang', calories: 340, p: 20, c: 38, f: 11, meal: 'DINNER', icon: Icons.kebab_dining_rounded, dist: 2100, address: '150 Huế, Hai Bà Trưng'),
      (name: 'Cơm Rang Dưa Bò', calories: 580, p: 30, c: 68, f: 18, meal: 'DINNER', icon: Icons.rice_bowl_rounded, dist: 2800, address: '200 Trần Khát Chân'),
      (name: 'Chè Hạt Sen Long Nhãn', calories: 160, p: 4, c: 34, f: 2, meal: 'SNACK', icon: Icons.icecream_rounded, dist: 420, address: '18 Hàng Gai, Hoàn Kiếm'),
      (name: 'Cháo Gà Hạt Sen', calories: 290, p: 18, c: 36, f: 7, meal: 'BREAKFAST', icon: Icons.soup_kitchen_rounded, dist: 1100, address: '55 Hàng Đường, Hoàn Kiếm'),
      (name: 'Salad Ức Gà Sốt Chanh', calories: 260, p: 35, c: 12, f: 6, meal: 'LUNCH', icon: Icons.eco_rounded, dist: 1600, address: '72 Trần Hưng Đạo'),
    ];

    final List<MapFoodPin> pins = [];

    for (int i = 0; i < seedData.length; i++) {
      final item = seedData[i];
      final angle = (i * (360 / seedData.length)) * (math.pi / 180);
      final radiusKm = item.dist / 1000.0;
      final latOffset = (radiusKm / 111.0) * math.cos(angle);
      final lngOffset = (radiusKm / (111.0 * math.cos(lat * math.pi / 180))) * math.sin(angle);

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

  @override
  Widget build(BuildContext context) {
    final centerLatLng = _currentPosition != null
        ? ((_currentPosition!.latitude - 37.42).abs() < 0.1
            ? _hanoiCenter
            : LatLng(_currentPosition!.latitude, _currentPosition!.longitude))
        : _hanoiCenter;

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
                          child: Icon(Icons.my_location_rounded, color: AppColors.primary, size: 24),
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
                            _mapController.move(pin.latLng, _mapController.camera.zoom);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.white : AppColors.primary,
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
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pin.name,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected ? Colors.white : AppColors.textDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${pin.caloriesKcal} kcal • ${pin.distanceFormatted}',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 9.5,
                                          color: isSelected ? Colors.white70 : AppColors.textSecondary,
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
            Positioned(
              top: 82,
              left: 16,
              right: 16,
              child: _buildFilterBar(),
            ),

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
                      _mapController.move(centerLatLng, 15.5);
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
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
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
                      _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: AppColors.textDark,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm món ăn trên bản đồ...',
                    hintStyle: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                Text(
                  _addressText,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          Container(
            height: 24,
            width: 1,
            color: Colors.grey.shade200,
          ),
          IconButton(
            tooltip: 'GPS Định vị',
            icon: const Icon(Icons.gps_fixed_rounded, color: AppColors.primary, size: 22),
            onPressed: _determinePosition,
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
          // Radius selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                DropdownButton<int>(
                  value: _selectedRadiusMeters,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 500, child: Text('Bán kính 500m')),
                    DropdownMenuItem(value: 1000, child: Text('Bán kính 1 km')),
                    DropdownMenuItem(value: 3000, child: Text('Bán kính 3 km')),
                    DropdownMenuItem(value: 5000, child: Text('Bán kính 5 km')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRadiusMeters = val);
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
        style: GoogleFonts.beVietnamPro(
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
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pin.distanceFormatted,
                            style: GoogleFonts.beVietnamPro(
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
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
              _buildMacroPill('${pin.caloriesKcal} kcal', 'Năng lượng', AppColors.primary),
              const SizedBox(width: 8),
              _buildMacroPill('${pin.proteinG}g', 'Protein', const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              _buildMacroPill('${pin.carbsG}g', 'Carbs', const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _buildMacroPill('${pin.fatG}g', 'Chất béo', const Color(0xFFDC2626)),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _mapController.move(pin.latLng, 16.5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã định vị chỉ đường tới ${pin.name} (${pin.distanceFormatted}).'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Dẫn đường'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await showMealLogSheet(context, loggedAt: DateTime.now());
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ghi bữa ăn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
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
