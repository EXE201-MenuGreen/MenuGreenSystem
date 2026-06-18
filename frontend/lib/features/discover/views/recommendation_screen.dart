import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/quick_recommendation_card.dart';
import '../widgets/recommendation_card.dart';
import 'budget_aware_screen.dart';
import 'recommendation_detail_screen.dart';
import 'recommendation_history_screen.dart';
import 'weekly_plan_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _provider = RecommendationProvider();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _provider.loadHistory(),
      _provider.loadFeedbackSummary(),
      _provider.loadTodayRecommendations(),
    ]);
  }

  void _openWeeklyPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyPlanScreen()),
    );
  }

  void _openBudgetAware() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BudgetAwareScreen()),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const RecommendationHistoryScreen()),
    );
  }

  void _openDetail(RecommendationHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationDetailScreen(historyItem: item),
      ),
    );
  }

  void _openCaloriesRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _RecommendationTypeScreen(
          title: 'Theo Calories',
          subtitle: 'Gợi ý món phù hợp với mục tiêu dinh dưỡng',
          icon: Icons.local_fire_department,
          mealType: 'calories',
        ),
      ),
    );
  }

  void _openLunchRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _RecommendationTypeScreen(
          title: 'Theo Bữa trưa',
          subtitle: 'Nhanh, tiết kiệm, đủ dinh dưỡng',
          icon: Icons.lunch_dining,
          mealType: 'lunch',
        ),
      ),
    );
  }

  void _openEcoRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _RecommendationTypeScreen(
          title: 'Tiết kiệm (Eco)',
          subtitle: 'Chi phí thấp, thời gian nấu ngắn',
          icon: Icons.eco,
          mealType: 'eco',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gợi ý cá nhân hóa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _PersonalizedInsight(),
            const SizedBox(height: 20),
            _buildTodaySection(),
            const SizedBox(height: 24),
            _buildExploreSection(),
            const SizedBox(height: 24),
            _buildHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.today, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            const Text(
              'Gợi ý hôm nay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<RecommendationProvider>(
          builder: (context, provider, _) {
            return QuickRecommendationCard(
              isLoading: provider.isLoadingToday,
              error: provider.todayError,
              breakfast: provider.todayBreakfast,
              lunch: provider.todayLunch,
              dinner: provider.todayDinner,
              hasAllergy: false,
              onRetry: _loadData,
              onUseAll: _openWeeklyPlan,
              onMealTap: _openMealDetail,
            );
          },
        ),
      ],
    );
  }

  void _openMealDetail(RecommendationItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationDetailScreen(
          recommendationItem: item,
        ),
      ),
    );
  }

  Widget _buildExploreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khám phá',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        _buildExploreCard(
          icon: Icons.local_fire_department,
          title: 'Theo Calories',
          subtitle: 'Gợi ý món phù hợp với mục tiêu dinh dưỡng',
          color: Colors.orange,
          onTap: _openCaloriesRecommendation,
        ),
        _buildExploreCard(
          icon: Icons.lunch_dining,
          title: 'Theo Bữa trưa',
          subtitle: 'Nhanh, tiết kiệm, đủ dinh dưỡng',
          color: Colors.blue,
          onTap: _openLunchRecommendation,
        ),
        _buildExploreCard(
          icon: Icons.eco,
          title: 'Tiết kiệm (Eco)',
          subtitle: 'Chi phí thấp, thời gian nấu ngắn',
          color: Colors.green,
          onTap: _openEcoRecommendation,
        ),
        _buildExploreCard(
          icon: Icons.calendar_month,
          title: 'Thực đơn tuần',
          subtitle: 'Lên kế hoạch ăn uống cả tuần',
          color: Colors.purple,
          onTap: _openWeeklyPlan,
        ),
        _buildExploreCard(
          icon: Icons.attach_money,
          title: 'Theo Ngân sách',
          subtitle: 'Tối ưu chi phí theo ngân sách',
          color: Colors.teal,
          onTap: _openBudgetAware,
        ),
      ],
    );
  }

  Widget _buildExploreCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Consumer<RecommendationProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch sử',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (provider.history.isNotEmpty)
                  TextButton(
                    onPressed: _openHistory,
                    child: const Text('Xem tất cả'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (provider.isLoadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (provider.history.isEmpty)
              _buildEmptyHistory()
            else
              ...provider.history.take(3).map(
                    (item) => _buildHistoryItem(item),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Chưa có lịch sử gợi ý',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(RecommendationHistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _openDetail(item),
        leading: _getMealTypeIcon(item.mealType),
        title: Text(
          _formatMealType(item.mealType),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.itemCount} món ${item.targetCalories != null ? '· ${item.targetCalories} kcal' : ''}',
        ),
        trailing: item.feedback != null
            ? Icon(
                item.feedback!.isLiked ? Icons.thumb_up : Icons.thumb_down,
                color: item.feedback!.isLiked ? Colors.green : Colors.orange,
                size: 20,
              )
            : Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _getMealTypeIcon(String mealType) {
    IconData icon;
    Color color;

    switch (mealType.toLowerCase()) {
      case 'breakfast':
        icon = Icons.wb_sunny_outlined;
        color = Colors.orange;
        break;
      case 'lunch':
        icon = Icons.lunch_dining;
        color = Colors.blue;
        break;
      case 'dinner':
        icon = Icons.dinner_dining;
        color = Colors.purple;
        break;
      case 'snack':
        icon = Icons.cookie;
        color = Colors.brown;
        break;
      default:
        icon = Icons.restaurant;
        color = AppColors.primary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    );
  }

  String _formatMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Gợi ý bữa sáng';
      case 'lunch':
        return 'Gợi ý bữa trưa';
      case 'dinner':
        return 'Gợi ý bữa tối';
      case 'snack':
        return 'Gợi ý bữa phụ';
      default:
        return 'Gợi ý ${mealType.toLowerCase()}';
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}

class _PersonalizedInsight extends StatelessWidget {
  const _PersonalizedInsight();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gợi ý này được cá nhân hóa theo mục tiêu và lịch sử đánh giá của bạn.',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTypeScreen extends StatefulWidget {
  const _RecommendationTypeScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.mealType,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String mealType;

  @override
  State<_RecommendationTypeScreen> createState() =>
      _RecommendationTypeScreenState();
}

class _RecommendationTypeScreenState extends State<_RecommendationTypeScreen> {
  final _provider = RecommendationProvider();
  List<RecommendationItem> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      switch (widget.mealType) {
        case 'calories':
          await _provider.loadCaloriesRecommendations();
          _items = _provider.calorieRecommendations;
          break;
        case 'lunch':
          await _provider.loadLunchRecommendations();
          _items = _provider.lunchRecommendations;
          break;
        case 'eco':
          await _provider.loadEcoRecommendations();
          _items = _provider.ecoRecommendations;
          break;
        default:
          await _provider.generateRecommendation(mealType: widget.mealType);
          _items = _provider.currentRecommendation?.items ?? [];
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _items.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRecommendations,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Không có gợi ý nào',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecommendationCard(
              item: item,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecommendationDetailScreen(
                      recommendationItem: item,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
