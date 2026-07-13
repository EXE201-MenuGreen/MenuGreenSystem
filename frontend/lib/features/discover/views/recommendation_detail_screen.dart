import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../providers/recommendation_provider.dart';
import '../repositories/food_discovery_repository.dart';
import '../views/food_detail_screen.dart';
import '../views/recipe_detail_screen.dart';
import '../widgets/feedback_buttons.dart';
import '../widgets/recommendation_item_tile.dart';
import '../widgets/score_breakdown_widget.dart';
import '../../meal_plan/providers/meal_plan_provider.dart';
import '../../meal_plan/models/meal_plan_requests.dart';

class RecommendationDetailScreen extends StatefulWidget {
  const RecommendationDetailScreen({
    super.key,
    this.historyItem,
    this.recommendationItem,
    this.recommendationResponse,
  });

  final RecommendationHistoryItem? historyItem;
  final RecommendationItem? recommendationItem;
  final RecommendationGenerateResponse? recommendationResponse;

  @override
  State<RecommendationDetailScreen> createState() => _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState extends State<RecommendationDetailScreen> {
  final _provider = RecommendationProvider();
  final _favoriteRepository = FoodDiscoveryRepository();

  RecommendationDetail? _detail;
  String? _explanation;
  bool _isLoading = true;
  bool _isSubmittingFeedback = false;
  bool _isApplyingToMealPlan = false;
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.historyItem != null) {
      await _loadFromHistory();
    } else if (widget.recommendationItem != null) {
      await _loadScores();
    } else if (widget.recommendationResponse != null) {
      _isLoading = false;
    }
  }

  Future<void> _loadFromHistory() async {
    if (widget.historyItem == null) return;

    setState(() => _isLoading = true);

    try {
      await _provider.loadDetail(widget.historyItem!.id);
      _detail = _provider.currentDetail;
      if (_detail != null) {
        await _provider.explain(_detail!.id);
        _explanation = _provider.explanation;
      }
    } catch (e) {
      // Handle error
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadScores() async {
    if (widget.recommendationItem == null) return;

    setState(() => _isLoading = true);

    try {
      await _provider.loadScores(
        calories: widget.recommendationItem!.caloriesKcal.round(),
      );
    } catch (e) {
      // Handle error
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFeedback(bool isLiked) async {
    if (widget.historyItem == null) return;

    setState(() => _isSubmittingFeedback = true);

    try {
      await _provider.submitFeedback(
        recommendationId: widget.historyItem!.id,
        isLiked: isLiked,
      );
    } catch (e) {
      // Handle error
    }

    if (mounted) {
      setState(() => _isSubmittingFeedback = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLiked ? 'Cảm ơn phản hồi tích cực!' : 'Cảm ơn phản hồi của bạn!',
          ),
        ),
      );
    }
  }

  Future<void> _applyToMealPlan() async {
    final item = widget.recommendationItem ??
        widget.recommendationResponse?.items.firstOrNull;

    if (item == null) return;

    setState(() => _isApplyingToMealPlan = true);

    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);

    final request = AddItemRequest(
      mealType: _resolveMealType(item),
      foodId: item.isFood ? item.id : null,
      recipeId: item.isFood ? null : item.id,
      targetCalories: item.caloriesKcal.round(),
      quantityG: 100,
    );

    final result = await mealPlanProvider.addRecommendationToTodayPlan(request);

    if (mounted) {
      setState(() => _isApplyingToMealPlan = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào kế hoạch ăn!')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final item = widget.recommendationItem ??
        widget.recommendationResponse?.items.firstOrNull;

    if (item == null || !item.isFood) return;

    setState(() => _isTogglingFavorite = true);

    try {
      final success = _isFavorite
          ? await _favoriteRepository.removeFavorite(item.id)
          : await _favoriteRepository.addFavorite(item.id);

      if (mounted) {
        setState(() => _isFavorite = success ? !_isFavorite : _isFavorite);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isFavorite ? 'Đã thêm vào yêu thích' : 'Đã bỏ yêu thích')),
          );
        }
      }
    } catch (_) {
      // Keep current state on error
    }

    if (mounted) {
      setState(() => _isTogglingFavorite = false);
    }
  }

  String _resolveMealType(RecommendationItem item) {
    final lower = item.mealType?.toLowerCase() ?? '';
    if (lower.contains('sáng') || lower.contains('breakfast')) return 'breakfast';
    if (lower.contains('trưa') || lower.contains('lunch')) return 'lunch';
    if (lower.contains('tối') || lower.contains('dinner')) return 'dinner';
    if (lower.contains('phụ') || lower.contains('snack')) return 'snack';
    return 'lunch';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết gợi ý'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.historyItem != null) {
      return _buildHistoryDetail();
    } else if (widget.recommendationItem != null) {
      return _buildItemDetail();
    } else if (widget.recommendationResponse != null) {
      return _buildResponseDetail();
    }

    return const Center(child: Text('Không có dữ liệu'));
  }

  Widget _buildHistoryDetail() {
    final item = widget.historyItem!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(item),
        const SizedBox(height: 24),
        if (_explanation != null) ...[
          _buildExplanationCard(),
          const SizedBox(height: 24),
        ],
        if (_detail != null) ...[
          _buildItemsList(_detail!.items),
          const SizedBox(height: 24),
          _buildHistoryMetadata(_detail!),
          const SizedBox(height: 24),
        ],
        _buildFeedbackSection(),
        const SizedBox(height: 24),
        _buildActions(),
      ],
    );
  }

  Widget _buildItemDetail() {
    final item = widget.recommendationItem!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildItemHeader(item),
        const SizedBox(height: 24),
        if (_provider.currentScore != null) ...[
          ScoreBreakdownWidget(score: _provider.currentScore!),
          const SizedBox(height: 24),
        ],
        _buildNutritionInfo(item),
        const SizedBox(height: 24),
        _buildActions(),
      ],
    );
  }

  Widget _buildResponseDetail() {
    final response = widget.recommendationResponse!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildResponseHeader(response),
        const SizedBox(height: 24),
        _buildItemsList(response.items),
        const SizedBox(height: 24),
        _buildActions(),
      ],
    );
  }

  Widget _buildHeader(RecommendationHistoryItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Số món', '${item.itemCount}'),
                if (item.targetCalories != null)
                  _buildStatItem('Calories', '${item.targetCalories}'),
                if (item.feedback != null)
                  _buildStatItem(
                    'Đánh giá',
                    item.feedback!.isLiked ? 'Thích' : 'Không thích',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseHeader(RecommendationGenerateResponse response) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gợi ý ${_formatMealType(response.mealType)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (response.targetCalories != null) ...[
              const SizedBox(height: 8),
              Text(
                'Mục tiêu: ${response.targetCalories} kcal',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Tổng: ${response.totalCalories} kcal',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (response.totalEstimatedCost != null || response.maxBudgetVnd != null) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (response.totalEstimatedCost != null)
                    'Chi phí: ${_formatPrice(response.totalEstimatedCost!)}',
                  if (response.maxBudgetVnd != null)
                    'Ngân sách: ${_formatPrice(response.maxBudgetVnd!)}',
                ].join(' · '),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(RecommendationItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.isFood ? Icons.restaurant : Icons.menu_book,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isFood ? Colors.blue.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.isFood ? 'Món ăn' : 'Công thức',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isFood ? Colors.blue : Colors.orange,
                              ),
                            ),
                          ),
                          if (item.score > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(item.score * 100).round()}% phù hợp',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.description != null) ...[
              const SizedBox(height: 12),
              Text(
                item.description!,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ],
            if (item.matchReason != null) ...[
              const SizedBox(height: 12),
              _buildInfoMessage(
                icon: Icons.auto_awesome,
                text: item.matchReason!,
                color: AppColors.primary,
              ),
            ],
            if (item.hasAllergyWarning) ...[
              const SizedBox(height: 12),
              _buildInfoMessage(
                icon: Icons.warning_amber_rounded,
                text: item.matchedAllergens.isEmpty
                    ? 'Món này cần được kiểm tra thêm về dị ứng.'
                    : 'Có thành phần cần lưu ý: ${item.matchedAllergens.join(', ')}',
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Vì sao được gợi ý?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _explanation!,
              style: TextStyle(
                color: Colors.blue.shade900,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<RecommendationItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách gợi ý (${items.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => RecommendationItemTile(
              item: item,
              onTap: () {
                if (item.isFood) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FoodDetailScreen(foodId: item.id),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipeId: item.id),
                    ),
                  );
                }
              },
            )),
      ],
    );
  }

  Widget _buildNutritionInfo(RecommendationItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin dinh dưỡng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                if (item.caloriesKcal > 0)
                  _buildNutrientItem('Calories', '${item.caloriesKcal.round()}', 'kcal', Colors.orange),
                if (item.proteinG > 0)
                  _buildNutrientItem('Protein', '${item.proteinG.round()}', 'g', Colors.red),
                if (item.carbsG > 0)
                  _buildNutrientItem('Carbs', '${item.carbsG.round()}', 'g', Colors.blue),
                if (item.fatG > 0)
                  _buildNutrientItem('Chất béo', '${item.fatG.round()}', 'g', Colors.purple),
                if (item.fiberG > 0)
                  _buildNutrientItem('Chất xơ', '${item.fiberG.round()}', 'g', Colors.teal),
                if (item.estimatedPriceVnd > 0)
                  _buildNutrientItem('Chi phí', _formatPrice(item.estimatedPriceVnd), '', Colors.green),
                if (item.displayTimeMin > 0)
                  _buildNutrientItem('Thời gian', '${item.displayTimeMin}', 'phút', Colors.indigo),
                if (item.servings != null)
                  _buildNutrientItem('Khẩu phần', '${item.servings}', 'người', Colors.brown),
              ],
            ),
            if (item.difficulty != null || item.instructions != null) ...[
              const SizedBox(height: 20),
              if (item.difficulty != null)
                Text('Độ khó: ${item.difficulty}', style: TextStyle(color: Colors.grey.shade700)),
              if (item.instructions != null) ...[
                if (item.difficulty != null) const SizedBox(height: 12),
                const Text('Hướng dẫn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(item.instructions!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientItem(String label, String value, String unit, Color color) {
    return SizedBox(
      width: 96,
      child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit.isNotEmpty ? '$label ($unit)' : label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildHistoryMetadata(RecommendationDetail detail) {
    if (detail.type == null && detail.confidence == null && detail.input == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin tạo gợi ý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (detail.type != null) ...[
              const SizedBox(height: 10),
              Text('Loại: ${detail.type}', style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (detail.confidence != null) ...[
              const SizedBox(height: 6),
              Text(
                'Độ tin cậy: ${(detail.confidence! * 100).round()}%',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMessage({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: color, height: 1.35))),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn thấy gợi ý này như thế nào?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FeedbackButtons(
              isLoading: _isSubmittingFeedback,
              onLike: () => _submitFeedback(true),
              onDislike: () => _submitFeedback(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final currentItem = widget.recommendationItem ??
        widget.recommendationResponse?.items.firstOrNull;

    if (widget.historyItem != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isApplyingToMealPlan ? null : _applyToMealPlan,
              icon: _isApplyingToMealPlan
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: Text(_isApplyingToMealPlan ? 'Đang thêm...' : 'Áp dụng vào kế hoạch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final hasItem = currentItem != null;

    if (!hasItem) {
      return const SizedBox.shrink();
    }

    final canFavorite = currentItem.isFood;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canFavorite
                ? (_isTogglingFavorite ? null : _toggleFavorite)
                : null,
            icon: _isTogglingFavorite
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    canFavorite
                        ? (_isFavorite ? Icons.favorite : Icons.favorite_border)
                        : Icons.block,
                  ),
            label: Text(canFavorite
                ? (_isFavorite ? 'Đã yêu thích' : 'Lưu')
                : 'Chỉ hỗ trợ món ăn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: canFavorite && _isFavorite ? Colors.red : null,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isApplyingToMealPlan ? null : _applyToMealPlan,
            icon: _isApplyingToMealPlan
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.add),
            label: Text(_isApplyingToMealPlan ? 'Đang thêm...' : 'Áp dụng'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return '$price';
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
