import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

typedef MealLogSubmitter =
    Future<bool?> Function(
      String mealType,
      double quantityG,
      CatalogItem? selectedItem,
    );

class SearchAndLogModal extends StatefulWidget {
  const SearchAndLogModal({
    super.key,
    required this.repository,
    required this.keyword,
    required this.defaultGrams,
    required this.isRecipe,
    required this.onSuccess,
    this.isIngredient = false,
    this.initialMealType = 'breakfast',
    this.fallbackNutrition,
    this.fallbackNutritionMultiplier = 1,
    this.submitter,
    this.syncsOfficePlan = false,
  });

  final NutritionTrackingRepository repository;
  final String keyword;
  final double defaultGrams;
  final bool isRecipe;
  final bool isIngredient;
  final VoidCallback onSuccess;
  final String initialMealType;
  final CvNutritionInfo? fallbackNutrition;
  final double fallbackNutritionMultiplier;
  final MealLogSubmitter? submitter;
  final bool syncsOfficePlan;

  @override
  State<SearchAndLogModal> createState() => _SearchAndLogModalState();
}

class _SearchAndLogModalState extends State<SearchAndLogModal> {
  bool _searching = true;
  List<CatalogItem> _searchResults = [];
  CatalogItem? _selectedItem;
  late String _mealType;
  final _gramsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
    _gramsController.text = widget.defaultGrams.toStringAsFixed(0);
    _searchDatabaseItem();
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _searchDatabaseItem() async {
    try {
      final results = widget.isIngredient
          ? await widget.repository.getIngredients(keyword: widget.keyword)
          : widget.isRecipe
          ? await widget.repository.getRecipes(keyword: widget.keyword)
          : await widget.repository.getFoods(keyword: widget.keyword);

      if (mounted) {
        setState(() {
          _searchResults = results;
          if (results.isNotEmpty) {
            _selectedItem = results.first;
          }
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _logMeal() async {
    final selectedItem = _selectedItem;
    final fallbackNutrition = widget.fallbackNutrition;
    if (selectedItem == null && fallbackNutrition == null) return;
    final qty = double.tryParse(_gramsController.text.trim()) ?? 0;
    if (qty <= 0) return;

    setState(() => _searching = true);

    try {
      final ingredientRatio = widget.isIngredient ? qty / 100 : 0.0;
      final ok = widget.submitter != null
          ? await widget.submitter!(_mealType, qty, selectedItem)
          : await widget.repository.createMealLog(
              foodId: widget.isRecipe || widget.isIngredient
                  ? null
                  : selectedItem?.id,
              recipeId: widget.isRecipe ? selectedItem?.id : null,
              mealType: _mealType,
              quantityG: qty,
              notes: widget.isIngredient
                  ? 'Nguyên liệu nhận diện từ AI scan: ${widget.keyword}'
                  : selectedItem == null
                  ? 'Ước tính từ AI scan: ${widget.keyword}'
                  : null,
              customName: widget.isIngredient
                  ? selectedItem?.name ?? widget.keyword
                  : selectedItem == null
                  ? widget.keyword
                  : null,
              sourceType: widget.isIngredient
                  ? 'AiIngredientScan'
                  : fallbackNutrition != null
                  ? 'AiDishScan'
                  : null,
              loggedAt: DateTime.now(),
              caloriesKcal: widget.isIngredient
                  ? (selectedItem?.caloriesKcal ?? 0) * ingredientRatio
                  : selectedItem == null
                  ? fallbackNutrition!.tongCalories *
                        widget.fallbackNutritionMultiplier
                  : null,
              proteinG: widget.isIngredient
                  ? (selectedItem?.proteinG ?? 0) * ingredientRatio
                  : selectedItem == null
                  ? fallbackNutrition!.proteinG *
                        widget.fallbackNutritionMultiplier
                  : null,
              carbsG: widget.isIngredient
                  ? (selectedItem?.carbsG ?? 0) * ingredientRatio
                  : selectedItem == null
                  ? fallbackNutrition!.carbsG *
                        widget.fallbackNutritionMultiplier
                  : null,
              fatG: widget.isIngredient
                  ? (selectedItem?.fatG ?? 0) * ingredientRatio
                  : selectedItem == null
                  ? fallbackNutrition!.fatG * widget.fallbackNutritionMultiplier
                  : null,
            );

      if (!mounted) return;

      if (ok == null) {
        setState(() => _searching = false);
        return;
      }

      if (ok) {
        widget.onSuccess();
      } else {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không ghi được nhật ký bữa ăn. Vui lòng kiểm tra lại.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isRecipe ? 'Xác nhận món ăn' : 'Xác nhận nguyên liệu'),
      content: _searching
          ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chọn dữ liệu phù hợp với “${widget.keyword}” để lưu đúng chỉ số dinh dưỡng.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_searchResults.isEmpty)
                    Text(
                      widget.fallbackNutrition != null
                          ? 'Chưa có món khớp trong dữ liệu hệ thống. Bạn vẫn có thể lưu bằng chỉ số dinh dưỡng do AI ước tính.'
                          : 'Không tìm thấy món hoặc nguyên liệu phù hợp trong dữ liệu hệ thống.',
                      style: TextStyle(
                        color: widget.fallbackNutrition != null
                            ? AppColors.textSecondary
                            : Colors.redAccent,
                        fontSize: 13,
                      ),
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Món được chọn',
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CatalogItem>(
                          value: _selectedItem,
                          isExpanded: true,
                          items: _searchResults
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (item) =>
                              setState(() => _selectedItem = item),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (widget.syncsOfficePlan) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Món này sẽ được ghi vào Nhật ký và cập nhật kế hoạch Office hôm nay.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Bữa ăn'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mealType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'breakfast',
                            child: Text('Bữa sáng'),
                          ),
                          DropdownMenuItem(
                            value: 'lunch',
                            child: Text('Bữa trưa'),
                          ),
                          DropdownMenuItem(
                            value: 'dinner',
                            child: Text('Bữa tối'),
                          ),
                          DropdownMenuItem(
                            value: 'snack',
                            child: Text('Bữa phụ'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _mealType = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gramsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.isRecipe
                          ? 'Khối lượng khẩu phần (gram)'
                          : 'Khối lượng (gram)',
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        if (!_searching &&
            (_selectedItem != null || widget.fallbackNutrition != null))
          ElevatedButton(
            onPressed: _logMeal,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              widget.syncsOfficePlan
                  ? 'Xác nhận và cập nhật'
                  : _selectedItem == null
                  ? 'Xác nhận món ăn'
                  : 'Thêm vào bữa ăn',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
