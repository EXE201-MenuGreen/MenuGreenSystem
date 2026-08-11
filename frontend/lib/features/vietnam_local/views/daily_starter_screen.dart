import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/discover_view.dart';
import '../../meal_plan/views/meal_plan_screen.dart';
import '../../tracking/widgets/meal_log_sheet.dart';
import '../models/vietnam_local_models.dart';
import '../providers/daily_starter_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';

/// Daily Starter — `2.12 Beginner Quick-Start` ("Hôm nay ăn gì?").
///
/// For Free users: shows today's welcome + target calories, a list of
/// suggested foods to browse, and offers self-service entry points
/// (Discover, Meal Plan, Weight Log) instead of "one-tap add to plan"
/// (which is a Casual feature).
class DailyStarterScreen extends StatefulWidget {
  const DailyStarterScreen({super.key});

  @override
  State<DailyStarterScreen> createState() => _DailyStarterScreenState();
}

class _DailyStarterScreenState extends State<DailyStarterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyStarterProvider>().loadAll();
    });
  }

  void _openFoodDetail(DailyStarterFood food) {
    if (food.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin món ăn.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: food.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hôm nay ăn gì?',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Consumer<DailyStarterProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.loadAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHero(provider),
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Gợi ý cho hôm nay',
                    subtitle: 'Món ăn phù hợp với mục tiêu calo của bạn',
                    icon: Icons.bolt,
                  ),
                  const SizedBox(height: 8),
                  _buildRandomBar(provider),
                  const SizedBox(height: 8),
                  if (provider.randomHighlight != null)
                    _buildHighlightCard(provider),
                  if (provider.randomHighlight != null)
                    const SizedBox(height: 12),
                  _buildFeaturedList(provider),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Hoặc tự chọn món',
                    subtitle: 'Chủ động tìm món, mở kế hoạch hoặc ghi nhanh',
                    icon: Icons.tune,
                  ),
                  const SizedBox(height: 12),
                  _buildSelfServiceActions(),
                  const SizedBox(height: 24),
                  if (provider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(DailyStarterProvider provider) {
    final today = provider.today;
    final loading = provider.isLoading;
    final welcome = today?.welcomeMessage;
    return InfoCard(
      icon: Icons.wb_sunny_outlined,
      title: (welcome != null && welcome.trim().isNotEmpty)
          ? welcome
          : 'MenuGreen chào bạn!',
      subtitle: today == null
          ? (loading
                ? 'Đang tải thông tin hôm nay...'
                : 'Hôm nay ăn gì? chọn nhanh cho bạn.')
          : 'Mục tiêu hôm nay: ${today.caloriesTarget.toStringAsFixed(0)} kcal'
                '${today.hasLoggedToday ? ' • Đã ghi nhật ký' : ' • Chưa ghi nhật ký'}',
      trailing: today?.quote.trim().isNotEmpty == true
          ? Tooltip(
              message: today!.quote,
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
              ),
            )
          : null,
      child: today?.quote.trim().isNotEmpty == true
          ? Text(
              '"${today!.quote}"',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          : null,
    );
  }

  Widget _buildRandomBar(DailyStarterProvider provider) {
    final remaining = provider.randomRemaining;
    final canTap = remaining > 0 && !provider.isRandomPicking;
    return Row(
      children: [
        Expanded(
          child: Text(
            remaining > 0
                ? 'Còn $remaining/${DailyStarterProvider.randomDailyLimit} lượt gợi ý ngẫu nhiên hôm nay.'
                : 'Đã dùng hết ${DailyStarterProvider.randomDailyLimit}/${DailyStarterProvider.randomDailyLimit} lượt hôm nay.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: canTap
              ? () async {
                  final picked = await provider.pickRandomHighlight();
                  if (picked == null && mounted) {
                    final msg =
                        provider.randomErrorMessage ??
                        'Không thể gợi ý lúc này.';
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(msg)));
                  }
                }
              : null,
          icon: provider.isRandomPicking
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.casino, size: 18),
          label: Text(remaining > 0 ? 'Random món' : 'Hết lượt'),
          style: TextButton.styleFrom(
            foregroundColor: remaining > 0
                ? AppColors.primary
                : AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(DailyStarterProvider provider) {
    final food = provider.randomHighlight!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Opacity(opacity: scale == 1 ? 1 : 0.85, child: child),
      child: Material(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openFoodDetail(food),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.casino, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Ngẫu nhiên',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name.isEmpty ? 'Món gợi ý' : food.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatNutritionFacts(
                          quantityG: food.defaultServingG,
                          caloriesKcal: food.caloriesKcal,
                          proteinG: food.proteinG,
                          carbsG: food.carbsG,
                          fatG: food.fatG,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Bỏ gợi ý ngẫu nhiên',
                  onPressed: provider.clearRandomHighlight,
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedList(DailyStarterProvider provider) {
    if (provider.isLoading && provider.featured.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (provider.featured.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.progressBackground),
        ),
        child: const Text(
          'Chưa có món gợi ý nào. Hãy thử tải lại trang.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        for (final food in provider.featured)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openFoodDetail(food),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.progressBackground),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food.name.isEmpty ? 'Món gợi ý' : food.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatNutritionFacts(
                                quantityG: food.defaultServingG,
                                caloriesKcal: food.caloriesKcal,
                                proteinG: food.proteinG,
                                carbsG: food.carbsG,
                                fatG: food.fatG,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openFoodDetail(food),
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: const Text('Xem chi tiết'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelfServiceActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SelfServiceCard(
                icon: Icons.search,
                title: 'Tìm món theo ý thích',
                subtitle: 'Lọc theo vùng miền, dị ứng',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DiscoverView(isStandalone: true),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SelfServiceCard(
                icon: Icons.calendar_today_outlined,
                title: 'Kế hoạch hôm nay',
                subtitle: 'Mở hoặc tạo kế hoạch ăn',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SelfServiceCard(
          icon: Icons.edit_note,
          title: 'Ghi bữa ăn nhanh',
          subtitle: 'Ước tính calo khi ăn ngoài',
          onTap: () async {
            await showMealLogSheet(context);
          },
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SelfServiceCard extends StatelessWidget {
  const _SelfServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.progressBackground),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
