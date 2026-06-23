import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../providers/recommendation_provider.dart';
import 'recommendation_detail_screen.dart';

class RecommendationHistoryScreen extends StatefulWidget {
  const RecommendationHistoryScreen({super.key});

  @override
  State<RecommendationHistoryScreen> createState() => _RecommendationHistoryScreenState();
}

class _RecommendationHistoryScreenState extends State<RecommendationHistoryScreen> {
  final _provider = RecommendationProvider();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _provider.loadHistory();
  }

  void _openDetail(RecommendationHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationDetailScreen(historyItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử gợi ý'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: [
          IconButton(
            onPressed: () => _showFilterOptions(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingHistory) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.history.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: _buildHistoryList(provider.history),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử gợi ý',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các gợi ý bạn đã xem sẽ hiển thị ở đây',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<RecommendationHistoryItem> items) {
    final grouped = _groupByDate(items);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(entry.key),
            ...entry.value.map((item) => _buildHistoryItem(item)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
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
      child: InkWell(
        onTap: () => _openDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _getMealTypeIcon(item.mealType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatMealType(item.mealType),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.itemCount} món',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        if (item.targetCalories != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.orange.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.targetCalories} kcal',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildFeedbackIndicator(item.feedback),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
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

  Widget _buildFeedbackIndicator(RecommendationFeedback? feedback) {
    if (feedback == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: feedback.isLiked
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            feedback.isLiked ? Icons.thumb_up : Icons.thumb_down,
            size: 14,
            color: feedback.isLiked ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            feedback.isLiked ? 'Thích' : 'Không',
            style: TextStyle(
              fontSize: 12,
              color: feedback.isLiked ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<RecommendationHistoryItem>> _groupByDate(
    List<RecommendationHistoryItem> items,
  ) {
    final grouped = <String, List<RecommendationHistoryItem>>{};

    for (final item in items) {
      final dateKey = _getDateKey(item.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Hôm nay';
    } else if (itemDate == yesterday) {
      return 'Hôm qua';
    } else if (itemDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'Tuần này';
    } else if (itemDate.isAfter(today.subtract(const Duration(days: 30)))) {
      return 'Tháng này';
    } else {
      return 'Trước đó';
    }
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

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc theo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('Tất cả', Icons.list, null),
            _buildFilterOption('Bữa sáng', Icons.wb_sunny_outlined, 'breakfast'),
            _buildFilterOption('Bữa trưa', Icons.lunch_dining, 'lunch'),
            _buildFilterOption('Bữa tối', Icons.dinner_dining, 'dinner'),
            _buildFilterOption('Bữa phụ', Icons.cookie, 'snack'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon, String? mealType) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        // Apply filter
      },
    );
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
