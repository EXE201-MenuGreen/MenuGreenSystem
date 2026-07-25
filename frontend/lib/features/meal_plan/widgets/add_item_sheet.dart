import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/models/food_models.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../models/meal_plan_requests.dart';

/// Bottom sheet để thêm món vào meal plan
/// Inspired by MyFitnessPal và Lose It! add food flow
class AddItemSheet extends StatefulWidget {
  const AddItemSheet({
    super.key,
    required this.planId,
    required this.mealType,
    this.scheduledTime,
    this.plannedDate,
    this.targetCalories,
    this.onItemAdded,
  });

  final String planId;
  final MealType mealType;
  final DateTime? scheduledTime;
  final DateTime? plannedDate;
  final int? targetCalories;
  final VoidCallback? onItemAdded;

  /// Hiển thị sheet và trả về AddItemRequest khi user xác nhận
  static Future<AddItemRequest?> show({
    required BuildContext context,
    required String planId,
    required MealType mealType,
    DateTime? scheduledTime,
    DateTime? plannedDate,
    int? targetCalories,
    VoidCallback? onItemAdded,
  }) {
    return showModalBottomSheet<AddItemRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        planId: planId,
        mealType: mealType,
        scheduledTime: scheduledTime,
        plannedDate: plannedDate ?? DateTime.now(),
        targetCalories: targetCalories,
        onItemAdded: onItemAdded,
      ),
    );
  }

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _repository = FoodDiscoveryRepository();

  Timer? _debounceTimer;
  bool _isSearching = false;

  List<dynamic> _searchResults = [];
  List<FavoriteFoodItem> _recentFoods = [];
  FoodItem? _selectedFood;
  RecipeItem? _selectedRecipe;
  int _selectedTab = 0; // 0 = Food, 1 = Recipe

  int get _quantity => int.tryParse(_quantityController.text) ?? 100;
  double get _caloriesPer100g => _selectedFood?.caloriesKcal ?? 0;
  int get _estimatedCalories => ((_caloriesPer100g * _quantity) / 100).round();

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
    if (widget.targetCalories != null) {
      _quantityController.text = widget.targetCalories.toString();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentFoods() async {
    try {
      final favorites = await _repository.getFavorites();
      if (mounted) {
        setState(() => _recentFoods = favorites.take(6).toList());
      }
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(value);
    });
  }

  Future<void> _search(String keyword) async {
    try {
      if (_selectedTab == 0) {
        final results = await _repository.searchFoods(keyword: keyword);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } else {
        final results = await _repository.searchRecipes(keyword: keyword);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectFood(FoodItem food) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFood = food;
      _selectedRecipe = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _selectRecipe(RecipeItem recipe) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedRecipe = recipe;
      _selectedFood = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFood = null;
      _selectedRecipe = null;
      _quantityController.text = '100';
    });
  }

  Future<void> _confirmAdd() async {
    HapticFeedback.mediumImpact();

    final customName = _selectedFood?.nameVi ??
        _selectedRecipe?.title ??
        (_searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null);

    final request = AddItemRequest(
      mealType: widget.mealType.value,
      scheduledTime: widget.scheduledTime,
      plannedDate: widget.plannedDate ?? DateTime.now(),
      foodId: _selectedFood?.id,
      recipeId: _selectedRecipe?.id,
      targetCalories: _estimatedCalories > 0 ? _estimatedCalories : 350,
      quantityG: _quantity.toDouble(),
      origin: 'user', // User tạo từ tab Kế hoạch
      customName: customName,
    );

    Navigator.pop(context, request);
    widget.onItemAdded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          _buildHandle(),
          // Header
          _buildHeader(),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomPadding + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search section
                  _buildSearchSection(),
                  const SizedBox(height: 16),

                  // Selected item preview
                  if (_selectedFood != null || _selectedRecipe != null) ...[
                    _buildSelectedPreview(),
                    const SizedBox(height: 16),
                  ],

                  // Results or recent foods
                  if (_isSearching)
                    _buildLoading()
                  else if (_searchResults.isNotEmpty)
                    _buildSearchResults()
                  else if (_selectedFood == null && _selectedRecipe == null)
                    _buildRecentFoods(),
                ],
              ),
            ),
          ),
          // Bottom action
          if (_selectedFood != null ||
              _selectedRecipe != null ||
              _searchController.text.trim().isNotEmpty)
            _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.mealType.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.mealType.labelVi,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab switcher
        Row(
          children: [
            _buildTabButton(0, 'Món ăn'),
            const SizedBox(width: 12),
            _buildTabButton(1, 'Công thức'),
          ],
        ),
        const SizedBox(height: 12),
        // Search field
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: _selectedTab == 0
                ? 'Tìm món ăn...'
                : 'Tìm công thức...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.progressBackground),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.progressBackground),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _searchController.clear();
          _searchResults = [];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.progressBackground,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả tìm kiếm',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_searchResults.length, (index) {
          final item = _searchResults[index];
          if (item is FoodItem) {
            return _buildFoodResultItem(item);
          } else if (item is RecipeItem) {
            return _buildRecipeResultItem(item);
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildFoodResultItem(FoodItem food) {
    return _FoodResultTile(
      food: food,
      onTap: () => _selectFood(food),
    );
  }

  Widget _buildRecipeResultItem(RecipeItem recipe) {
    return _RecipeResultTile(
      recipe: recipe,
      onTap: () => _selectRecipe(recipe),
    );
  }

  Widget _buildRecentFoods() {
    if (_recentFoods.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÓN ĂN GẦN ĐÂY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentFoods.map((fav) {
            return _RecentFoodChip(
              favorite: fav,
              onTap: () async {
                final food = await _repository.getFoodById(fav.foodId);
                if (food != null && mounted) {
                  _selectFood(food);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        // Empty state hint
        Center(
          child: Column(
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Tìm kiếm món ăn hoặc công thức',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy món ăn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                      _selectedFood?.nameVi ?? _selectedRecipe?.title ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedFood?.caloriesKcal?.toStringAsFixed(0) ?? "?"} kcal / 100g',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
                tooltip: 'Bỏ chọn',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quantity input
          Row(
            children: [
              const Text(
                'Khẩu phần (g):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    suffixText: 'g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Calorie preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ước tính calories:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$_estimatedCalories kcal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _confirmAdd,
            icon: const Icon(Icons.add),
            label: const Text('Thêm vào kế hoạch'),
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
      ),
    );
  }
}

/// Tile hiển thị kết quả tìm kiếm food
class _FoodResultTile extends StatelessWidget {
  const _FoodResultTile({
    required this.food,
    required this.onTap,
  });

  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.progressBackground),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.nameVi,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${food.caloriesKcal?.toStringAsFixed(0) ?? "?"} kcal / 100g',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile hiển thị kết quả tìm kiếm recipe
class _RecipeResultTile extends StatelessWidget {
  const _RecipeResultTile({
    required this.recipe,
    required this.onTap,
  });

  final RecipeItem recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.progressBackground),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (recipe.prepTimeMin != null)
                      Text(
                        '~${recipe.prepTimeMin} phút',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip hiển thị món ăn gần đây
class _RecentFoodChip extends StatelessWidget {
  const _RecentFoodChip({
    required this.favorite,
    required this.onTap,
  });

  final FavoriteFoodItem favorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.progressBackground),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              favorite.nameVi,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
