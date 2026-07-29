import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';
import '../providers/favorite_food_provider.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/recommendation_card.dart';
import 'recommendation_detail_screen.dart';

class BudgetAwareScreen extends StatefulWidget {
  const BudgetAwareScreen({super.key});

  @override
  State<BudgetAwareScreen> createState() => _BudgetAwareScreenState();
}

class _BudgetAwareScreenState extends State<BudgetAwareScreen> {
  final _provider = RecommendationProvider();

  @override
  void initState() {
    super.initState();
    context.read<FavoriteFoodProvider>().load();
  }

  String? _selectedMealType;
  int _maxBudgetVnd = 100000;
  int? _targetCalories;
  bool _excludeUserAllergies = false;

  final List<Map<String, dynamic>> _mealTypes = [
    {'value': null, 'label': 'Tất cả'},
    {'value': 'breakfast', 'label': 'Bữa sáng'},
    {'value': 'lunch', 'label': 'Bữa trưa'},
    {'value': 'dinner', 'label': 'Bữa tối'},
    {'value': 'snack', 'label': 'Bữa phụ'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Theo Ngân sách'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: _provider.budgetPlan == null ? _buildConfigForm() : _buildResult(),
    );
  }

  Widget _buildConfigForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
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
                  'Ngân sách tối đa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCurrency(_maxBudgetVnd),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Slider(
                  value: _maxBudgetVnd.toDouble(),
                  min: 20000,
                  max: 500000,
                  divisions: 48,
                  label: _formatCurrency(_maxBudgetVnd),
                  onChanged: (value) {
                    setState(() {
                      _maxBudgetVnd = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '20K',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '500K',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
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
                  'Bữa ăn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _mealTypes.map((type) {
                    final isSelected = _selectedMealType == type['value'];
                    return ChoiceChip(
                      label: Text(type['label']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMealType = selected ? type['value'] : null;
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calories mục tiêu (tùy chọn)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_targetCalories != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _targetCalories = null;
                          });
                        },
                        child: const Text('Xóa'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'VD: 2000',
                    suffixText: 'kcal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _targetCalories = int.tryParse(value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: SwitchListTile(
            title: const Text('Loại trừ dị ứng'),
            subtitle: const Text('Tự động loại bỏ các món có thể gây dị ứng'),
            value: _excludeUserAllergies,
            onChanged: (value) {
              setState(() {
                _excludeUserAllergies = value;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _provider.isGenerating ? null : _generatePlan,
            icon: _provider.isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(_provider.isGenerating ? 'Đang tìm...' : 'Tìm gợi ý'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final plan = _provider.budgetPlan!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: plan.isWithinBudget
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ngân sách tối đa:'),
                  Text(
                    _formatCurrency(plan.maxBudgetVnd),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chi phí ước tính:'),
                  Text(
                    _formatCurrency(plan.totalEstimatedCost),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: plan.isWithinBudget ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              if (plan.savingsVnd != null && plan.savingsVnd! > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tiết kiệm được:'),
                    Text(
                      _formatCurrency(plan.savingsVnd!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Gợi ý tiết kiệm',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...plan.items.map(
          (item) => Consumer<FavoriteFoodProvider>(
            builder: (context, favorites, _) => RecommendationCard(
              item: item,
              isFavorite: item.isFood && favorites.isFavorite(item.id),
              isFavoriteBusy: favorites.isMutating(item.id),
              onFavorite: item.isFood
                  ? () async {
                      final result = await favorites.toggle(
                        FavoriteFoodItem.fromRecommendation(item),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.isSuccess
                              ? AppColors.primary
                              : Colors.red.shade700,
                        ),
                      );
                    }
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RecommendationDetailScreen(recommendationItem: item),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _provider.clearBudgetPlan();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tìm lại'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generatePlan() async {
    setState(() {});
    await _provider.generateBudgetAware(
      mealType: _selectedMealType,
      maxBudgetVnd: _maxBudgetVnd,
      targetCalories: _targetCalories,
      excludeUserAllergies: _excludeUserAllergies,
    );

    if (!mounted) return;
    setState(() {});
    if (_provider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${_provider.error}')));
    }
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '$formatted VNĐ';
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
