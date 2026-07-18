import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

class SearchAndLogModal extends StatefulWidget {
  const SearchAndLogModal({
    super.key,
    required this.repository,
    required this.keyword,
    required this.defaultGrams,
    required this.isRecipe,
    required this.onSuccess,
    this.initialMealType = 'breakfast',
  });

  final NutritionTrackingRepository repository;
  final String keyword;
  final double defaultGrams;
  final bool isRecipe;
  final VoidCallback onSuccess;
  final String initialMealType;

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
      final results = widget.isRecipe
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
    if (_selectedItem == null) return;
    final qty = double.tryParse(_gramsController.text.trim()) ?? 0;
    if (qty <= 0) return;

    setState(() => _searching = true);

    try {
      final ok = await widget.repository.createMealLog(
        foodId: widget.isRecipe ? null : _selectedItem!.id,
        recipeId: widget.isRecipe ? _selectedItem!.id : null,
        mealType: _mealType,
        quantityG: qty,
        loggedAt: DateTime.now(),
      );

      if (!mounted) return;

      if (ok) {
        widget.onSuccess();
      } else {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không ghi được nhật ký bữa ăn. Vui lòng kiểm tra lại.'),
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
      title: Text(
        widget.isRecipe ? 'Xác nhận món ăn' : 'Xác nhận nguyên liệu',
      ),
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
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_searchResults.isEmpty)
                    const Text(
                      'Không tìm thấy món hoặc nguyên liệu phù hợp trong dữ liệu hệ thống.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
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
                                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (item) => setState(() => _selectedItem = item),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Bữa ăn'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _mealType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                          DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                          DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                          DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
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
        if (!_searching && _selectedItem != null)
          ElevatedButton(
            onPressed: _logMeal,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Thêm vào bữa ăn',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
