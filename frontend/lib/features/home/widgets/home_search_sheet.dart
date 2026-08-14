import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../casual/views/casual_hub_screen.dart';
import '../../discover/models/food_models.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../../discover/views/favorites_screen.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../gymer/views/gymer_hub_screen.dart';
import '../../meal_plan/views/smart_meal_plan_router_screen.dart';
import '../../meal_templates/views/meal_templates_screen.dart';
import '../../office/views/office_workspace_screen.dart';
import '../../subscription/views/upgrade_plan_screen.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import '../../vietnam_local/views/food_capture_screen.dart';
import '../../vietnam_local/views/ingredient_substitution_screen.dart';
import '../../vietnam_local/views/local_preferences_screen.dart';
import '../../vietnam_local/views/planned_vs_actual_screen.dart';
import '../../vietnam_local/views/safety_hub_screen.dart';
import 'weight_log_sheet.dart';

class HomeFeatureSearchItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> keywords;
  final VoidCallback onTap;

  const HomeFeatureSearchItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.keywords,
    required this.onTap,
  });
}

class HomeSearchSheet extends StatefulWidget {
  const HomeSearchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeSearchSheet(),
    );
  }

  @override
  State<HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends State<HomeSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FoodDiscoveryRepository _foodRepo = FoodDiscoveryRepository();
  Timer? _debounceTimer;

  List<FoodItem> _foodResults = [];
  bool _isSearchingFoods = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<HomeFeatureSearchItem> _buildFeaturesList(BuildContext context) {
    return [
      HomeFeatureSearchItem(
        title: 'Hôm nay ăn gì?',
        description: 'Bắt đầu ngày mới với thực đơn gợi ý',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF1B4332),
        keywords: ['hom nay an gi', 'goi y', 'daily starter', 'thuc don'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CasualHubScreen(
                openFeature: CasualFeature.dailyStarter,
              ),
            ),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Theo dõi cân nặng',
        description: 'Cập nhật chỉ số cân nặng hàng ngày',
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFF059669),
        keywords: ['can nang', 'weight', 'theo doi', 'bmi', 'giam can'],
        onTap: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const WeightLogSheet(),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Tính calo & Quét nguyên liệu',
        description: 'Quét ảnh hoặc tính lượng calo trong thực phẩm',
        icon: Icons.calculate_outlined,
        color: const Color(0xFF0891B2),
        keywords: ['tinh calo', 'quet anh', 'camera', 'scan', 'nguyen lieu'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IngredientScanScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Kế hoạch vs Thực tế',
        description: 'Đánh giá mức độ bám sát dinh dưỡng',
        icon: Icons.insights_rounded,
        color: const Color(0xFF7C3AED),
        keywords: [
          'ke hoach',
          'thuc te',
          'adherence',
          'adherence score',
          'diem',
          'tuan thu',
          'tuân thủ',
        ],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlannedVsActualScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Kế hoạch ăn uống',
        description: 'Xem và quản lý thực đơn tuần',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF0077B6),
        keywords: ['ke hoach an', 'meal plan', 'lich an', 'thuc don'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SmartMealPlanRouterScreen(),
            ),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Thay thế nguyên liệu',
        description: 'Tìm kiếm nguyên liệu thay thế linh hoạt',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF65A30D),
        keywords: ['thay the', 'nguyen lieu', 'substitute', 'doi mon'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IngredientSubstitutionScreen(),
            ),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Ăn ngoài & Nhập nhanh',
        description: 'Ghi chép món ăn quán, tiệc tùng',
        icon: Icons.no_food_outlined,
        color: const Color(0xFFEAB308),
        keywords: ['an ngoai', 'nha hang', 'quan', 'fast food', 'capture'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FoodCaptureScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Gói Gymer / PT',
        description: 'Tập luyện & thực đơn tăng cơ giảm mỡ',
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFFDC2626),
        keywords: ['gymer', 'pt', 'tap gym', 'workout', 'protein'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GymerHubScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Không gian Office',
        description: 'Đặt lịch ăn trưa dân văn phòng',
        icon: Icons.business_center_outlined,
        color: const Color(0xFF166534),
        keywords: ['office', 'van phong', 'com trua', 'cong ty'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OfficeWorkspaceScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Góc Cảm xúc (Micro Learning)',
        description: 'Mẹo ăn uống theo tâm trạng & kiến thức',
        icon: Icons.psychology_outlined,
        color: const Color(0xFF2563EB),
        keywords: ['cam xuc', 'micro learning', 'kien thuc', 'meo'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CasualHubScreen(
                openFeature: CasualFeature.microLearning,
              ),
            ),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Sở thích Việt Nam',
        description: 'Khẩu vị theo vùng miền Việt Nam',
        icon: Icons.storefront_rounded,
        color: const Color(0xFFEA580C),
        keywords: ['viet nam', 'local', 'khau vi', 'vung mien'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocalPreferencesScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Món ăn yêu thích',
        description: 'Danh sách món ăn bạn đã thả tim',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFDB2777),
        keywords: ['yeu thich', 'favorite', 'da luu', 'tim'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Thực đơn mẫu đã lưu',
        description: 'Mẫu bữa ăn bạn lưu dùng lại',
        icon: Icons.bookmark_outline_rounded,
        color: const Color(0xFF0F766E),
        keywords: ['thuc don mau', 'templates', 'luu'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MealTemplatesScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'An toàn & Tuân thủ',
        description: 'Quản lý dị ứng, cảnh báo sức khỏe',
        icon: Icons.security_rounded,
        color: const Color(0xFF9333EA),
        keywords: ['an toan', 'di ung', 'safety', 'tuat thu'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SafetyHubScreen()),
          );
        },
      ),
      HomeFeatureSearchItem(
        title: 'Nâng cấp Gói VIP',
        description: 'Đăng ký Casual Plus & Gymer VIP',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFD97706),
        keywords: ['vip', 'nang cap', 'upgrade', 'dich vu'],
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UpgradePlanScreen()),
          );
        },
      ),
    ];
  }

  void _onSearchChanged(String text) {
    setState(() {
      _query = text.trim();
    });

    _debounceTimer?.cancel();
    if (_query.isEmpty) {
      setState(() {
        _foodResults = [];
        _isSearchingFoods = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingFoods = true);

      try {
        final foods = await _foodRepo.searchFoods(keyword: _query);
        if (mounted) {
          setState(() {
            _foodResults = foods;
            _isSearchingFoods = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearchingFoods = false);
        }
      }
    });
  }

  String _removeDiacritics(String text) {
    var str = text.toLowerCase();
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'[đ]'), 'd');
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final allFeatures = _buildFeaturesList(context);
    final normalizedQuery = _removeDiacritics(_query);

    final filteredFeatures = _query.isEmpty
        ? allFeatures
        : allFeatures.where((f) {
            final titleNorm = _removeDiacritics(f.title);
            final descNorm = _removeDiacritics(f.description);
            final kwNorm = f.keywords.map(_removeDiacritics).toList();
            return titleNorm.contains(normalizedQuery) ||
                descNorm.contains(normalizedQuery) ||
                kwNorm.any((kw) => kw.contains(normalizedQuery));
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: beVietnamPro(
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Tìm chức năng (Cân nặng, Calo...) hoặc món ăn...',
                      hintStyle: beVietnamProHint(
                        fontSize: 13.5,
                        color: Colors.grey.shade500,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Section 1: Features
                    if (filteredFeatures.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.apps_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _query.isEmpty
                                ? 'Tính năng ứng dụng'
                                : 'Chức năng phù hợp (${filteredFeatures.length})',
                            style: beVietnamPro(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...filteredFeatures.map(
                        (feature) => _buildFeatureItem(feature),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section 2: Foods
                    if (_query.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Món ăn & Thực đơn',
                            style: beVietnamPro(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isSearchingFoods)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else if (_foodResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Không tìm thấy món ăn nào cho "$_query"',
                            style: beVietnamPro(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      else
                        ..._foodResults.map(
                          (food) => _buildFoodItem(context, food),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(HomeFeatureSearchItem feature) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: feature.onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: feature.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: feature.color, size: 22),
        ),
        title: Text(
          feature.title,
                            style: beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          feature.description,
                            style: beVietnamPro(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(foodId: food.id),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          food.nameVi,
                            style: beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          '${food.category ?? 'Món ăn'}\n'
          '${formatNutritionFacts(quantityG: food.defaultServingG, caloriesKcal: food.caloriesKcal, proteinG: food.proteinG, carbsG: food.carbsG, fatG: food.fatG)}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
                            style: beVietnamPro(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}
