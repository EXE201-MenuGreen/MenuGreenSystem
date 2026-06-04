import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/widgets/primary_button.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  final _tokenStorage = TokenStorage();
  final _profileRepository = ProfileRepository();
  final _trackingRepository = NutritionTrackingRepository();
  String _userName = 'MinMin';
  String? _avatarUrl;
  MealDaySummary? _todaySummary;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    refreshHeader();
    _loadTodaySummary();
  }

  Future<void> refreshHeader() async {
    final name = await _tokenStorage.getFullName();
    Map<String, dynamic>? profile;
    try {
      profile = await _profileRepository
          .getMyProfile()
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      profile = null;
    }
    if (!mounted) return;

    final rawAvatar = profile?['avatarUrl']?.toString();
    setState(() {
      if (name != null && name.isNotEmpty) _userName = name;
      final fullName = profile?['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) _userName = fullName;
      _avatarUrl = (rawAvatar != null && rawAvatar.isNotEmpty) ? rawAvatar : null;
    });
  }

  Future<void> _loadTodaySummary({bool userInitiated = false}) async {
    if (_refreshing) return;
    if (userInitiated) setState(() => _refreshing = true);
    try {
      final summary = await _trackingRepository
          .getDailySummary(DateTime.now())
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() => _todaySummary = summary);
    } catch (_) {
      if (!mounted) return;
      if (userInitiated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được dữ liệu. Kiểm tra mạng và thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted && userInitiated) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCalorieCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('Bữa ăn đề xuất', 'Tất cả'),
            const SizedBox(height: 16),
            _buildRecommendedMeal(context),
            const SizedBox(height: 32),
            _buildSectionHeader('Lựa chọn khác', ''),
            const SizedBox(height: 16),
            _buildOtherOptions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.progressBackground,
          backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
          child: hasAvatar
              ? null
              : const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHÀO BUỔI SÁNG!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_userName, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.progressBackground.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _refreshing
                ? null
                : () => _loadTodaySummary(userInitiated: true),
          ),
        )
      ],
    );
  }

  Widget _buildCalorieCard() {
    final summary = _todaySummary;
    final totalCalories = summary?.totalCalories ?? 0;
    final targetCalories = (summary?.targetCalories ?? 1850).clamp(1, 10000);
    final remainingCalories = (targetCalories - totalCalories).clamp(-99999, 99999);
    final progress = (totalCalories / targetCalories).clamp(0, 1).toDouble();
    final totalProtein = summary?.totalProteinG ?? 0;
    final totalCarbs = summary?.totalCarbsG ?? 0;
    final totalFat = summary?.totalFatG ?? 0;
    final targetProtein = (summary?.targetProteinG ?? 120).clamp(1, 10000);
    final targetCarbs = (summary?.targetCarbsG ?? 220).clamp(1, 10000);
    final targetFat = (summary?.targetFatG ?? 60).clamp(1, 10000);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.progressBackground, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TIẾN ĐỘ CALO HÔM NAY', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.ideographic,
                    children: [
                      Text('${totalCalories.toStringAsFixed(0)} ', style: const TextStyle(color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('/ ${targetCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Còn lại', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('${remainingCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.progressBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroInfo('PROTEIN', '${totalProtein.toStringAsFixed(0)}g', '${targetProtein.toStringAsFixed(0)}g'),
              _buildMacroInfo('CARBS', '${totalCarbs.toStringAsFixed(0)}g', '${targetCarbs.toStringAsFixed(0)}g'),
              _buildMacroInfo('CHẤT BÉO', '${totalFat.toStringAsFixed(0)}g', '${targetFat.toStringAsFixed(0)}g'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String current, String total) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('$current ', style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('/ $total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        if (action.isNotEmpty)
          Text(action, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildRecommendedMeal(BuildContext context) {
    final logs = _todaySummary?.mealLogs ?? [];
    final meal = logs.isNotEmpty ? logs.first : null;
    final mealType = _mealTypeLabel(meal?.mealType);
    final mealTitle = meal == null
        ? 'Chưa có dữ liệu bữa ăn hôm nay'
        : meal.displayName;
    final mealCalories = meal == null ? '0 kcal' : '${meal.caloriesKcal.toStringAsFixed(0)} kcal';
    final mealQty = meal == null ? '0 g' : '${meal.quantityG.toStringAsFixed(0)} g';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: AppColors.progressBackground,
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 48), // Placeholder for image
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('NHẬT KÝ $mealType'.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(mealTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Row(
                      children: [
                        Icon(Icons.star_border, size: 16, color: AppColors.textDark),
                        SizedBox(width: 4),
                        Text(logs.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(mealQty, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.local_fire_department_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(mealCalories, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  meal == null
                      ? 'Hãy thêm nhật ký bữa ăn để theo dõi calories và macro chính xác hơn.'
                      : 'Dữ liệu lấy từ nhật ký dinh dưỡng trong ngày của bạn.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: _refreshing ? 'Đang tải...' : 'Làm mới dữ liệu',
                    onPressed: _refreshing
                        ? null
                        : () => _loadTodaySummary(userInitiated: true),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOtherOptions() {
    return SizedBox(
      height: 200,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => notification.metrics.axis == Axis.horizontal,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: [
          _buildSmallMealCard('BỮA PHỤ', 'Smoothie Bơ Hạt', '220 kcal • 5 phút'),
          const SizedBox(width: 16),
          _buildSmallMealCard('ĂN CHAY', 'Poke Chay Cầu Vồng', '380 kcal • 15 phút'),
          const SizedBox(width: 16),
          _buildSmallMealCard('THUẦN CHAY', 'Salad Đậu Hũ', '250 kcal • 10 phút'),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMealCard(String tag, String title, String meta) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.progressBackground),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.progressBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Icon(Icons.fastfood_outlined, color: Colors.white, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _mealTypeLabel(String? mealType) {
    final value = mealType?.trim().toLowerCase() ?? '';
    switch (value) {
      case 'breakfast':
      case 'bữa sáng':
        return 'sáng';
      case 'lunch':
      case 'bữa trưa':
        return 'trưa';
      case 'dinner':
      case 'bữa tối':
        return 'tối';
      default:
        return 'phụ';
    }
  }
}
