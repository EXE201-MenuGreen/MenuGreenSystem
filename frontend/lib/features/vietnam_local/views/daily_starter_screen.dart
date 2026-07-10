import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../models/vietnam_local_models.dart';
import '../providers/daily_starter_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';
import 'daily_starter_personalization_screen.dart';

/// Daily Starter — `2.12 Beginner Quick-Start` ("Hôm nay ăn gì?").
///
/// Loads /DailyStarter/today + /DailyStarter/featured-meals and lets users
/// quickly apply a featured food to today's meal plan via select-meal.
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

  Future<void> _applyFeatured(DailyStarterFood food) async {
    final provider = context.read<DailyStarterProvider>();
    final result = await provider.selectMeal({
      'foodId': food.id,
      'name': food.name,
      'mealType': _guessMealType(),
      'calories': food.caloriesKcal,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiMessageTranslator.translate(result))),
    );
  }

  String _guessMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'Breakfast';
    if (hour < 14) return 'Lunch';
    if (hour < 19) return 'Dinner';
    return 'Snack';
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
                    title: 'Bữa nhanh gợi ý',
                    subtitle: 'Chạm để áp dụng vào kế hoạch hôm nay',
                    icon: Icons.bolt,
                  ),
                  const SizedBox(height: 12),
                  _buildFeaturedList(provider),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Hồ sơ cá nhân hóa',
                    subtitle: 'Cập nhật chiều cao, cân nặng và sở thích ăn uống',
                    icon: Icons.tune,
                  ),
                  const SizedBox(height: 12),
                  _buildPersonalizationCard(provider),
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
          ? (loading ? 'Đang tải thông tin hôm nay...' : 'Hôm nay ăn gì? chọn nhanh cho bạn.')
          : 'Mục tiêu hôm nay: ${today.caloriesTarget.toStringAsFixed(0)} kcal'
              '${today.hasLoggedToday ? ' • Đã ghi nhật ký' : ' • Chưa ghi nhật ký'}',
      trailing: today?.quote.trim().isNotEmpty == true
          ? Tooltip(
              message: today!.quote,
              child: const Icon(Icons.lightbulb_outline, color: AppColors.primary),
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

  Widget _buildFeaturedList(DailyStarterProvider provider) {
    if (provider.isLoading && provider.featured.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                onTap: () => _applyFeatured(food),
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
                        child: const Icon(Icons.restaurant, color: AppColors.primary),
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
                              '${food.caloriesKcal.toStringAsFixed(0)} kcal'
                              ' • P ${food.proteinG.toStringAsFixed(0)}g'
                              ' • C ${food.carbsG.toStringAsFixed(0)}g'
                              ' • F ${food.fatG.toStringAsFixed(0)}g',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_task, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalizationCard(DailyStarterProvider provider) {
    final p = provider.personalization;
    final loading = provider.isPersonalizationLoading;
    return InfoCard(
      icon: Icons.manage_search,
      title: 'Sở thích ăn uống',
      subtitle: p == null
          ? 'Đang tải...'
          : 'Mục tiêu calo: ${p.targetCalories?.toStringAsFixed(0) ?? '—'} kcal'
              ' • ${p.dietaryPreference ?? 'chưa thiết lập'}',
      value: p == null ? null : '${p.allergenKeys.length} dị ứng',
      footnote: p == null
          ? null
          : 'Chiều cao ${p.heightCm?.toStringAsFixed(0) ?? '—'} cm • '
              'Cân nặng ${p.weightKg?.toStringAsFixed(1) ?? '—'} kg',
      trailing: TextButton(
        onPressed: loading
            ? null
            : () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyStarterPersonalizationScreen(),
                  ),
                );
                if (changed == true && mounted) {
                  await provider.refreshPersonalization();
                }
              },
        child: const Text('Cập nhật'),
      ),
    );
  }
}
