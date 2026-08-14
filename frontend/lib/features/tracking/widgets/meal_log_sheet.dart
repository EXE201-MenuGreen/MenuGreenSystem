import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../history/views/history_view.dart';
import '../repositories/nutrition_tracking_repository.dart';

/// Dialog thêm nhật ký bữa ăn — dùng từ Lịch sử hoặc Chi tiết món.
Future<bool> showMealLogSheet(
  BuildContext context, {
  String? initialFoodId,
  String? initialFoodName,
  String? initialRecipeId,
  String? initialRecipeName,
  DateTime? loggedAt,
  double? caloriesKcal,
  double? proteinG,
  double? carbsG,
  double? fatG,
  NutritionTrackingRepository? repository,
}) async {
  final trackingRepository = repository ?? NutritionTrackingRepository();
  final draft = await showDialog<_MealLogDraft>(
    context: context,
    builder: (_) => _MealLogDialog(
      repository: trackingRepository,
      initialFoodId: initialFoodId,
      initialFoodName: initialFoodName,
      initialRecipeId: initialRecipeId,
      initialRecipeName: initialRecipeName,
    ),
  );

  if (draft == null) return false;

  final isCustomDish =
      initialFoodId == null &&
      initialRecipeId == null &&
      initialFoodName?.trim().isNotEmpty == true;
  final foodId =
      initialFoodId ??
      (!isCustomDish && draft.sourceType == 'food' ? draft.selectedId : null);
  final recipeId =
      initialRecipeId ??
      (!isCustomDish && draft.sourceType == 'recipe' ? draft.selectedId : null);
  final customName = isCustomDish
      ? initialFoodName!.trim()
      : (foodId == null && recipeId == null)
      ? (draft.keyword.isNotEmpty ? draft.keyword : null)
      : null;

  if (foodId == null &&
      recipeId == null &&
      (customName == null || customName.isEmpty)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập hoặc chọn tên món ăn trước khi ghi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  var success = false;
  try {
    success = await trackingRepository.createMealLog(
      foodId: foodId,
      recipeId: recipeId,
      customName: customName,
      notes: customName,
      mealType: draft.mealType,
      quantityG: draft.quantity,
      loggedAt: loggedAt ?? DateTime.now(),
      caloriesKcal: caloriesKcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  } catch (_) {
    success = false;
  }

  if (context.mounted) {
    final mealTypeName = switch (draft.mealType) {
      'breakfast' => 'Bữa sáng',
      'lunch' => 'Bữa trưa',
      'dinner' => 'Bữa tối',
      _ => 'Bữa phụ',
    };
    final name = initialFoodName ?? customName ?? 'Món ăn';
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Đã lưu "$name" vào $mealTypeName, Kế hoạch ăn uống và Lịch sử.',
          ),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'Xem nhật ký',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryView()),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể ghi nhật ký lúc này. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  return success;
}

class _MealLogDraft {
  const _MealLogDraft({
    required this.sourceType,
    required this.mealType,
    required this.quantity,
    required this.keyword,
    this.selectedId,
  });

  final String sourceType;
  final String mealType;
  final double quantity;
  final String keyword;
  final String? selectedId;
}

class _MealLogDialog extends StatefulWidget {
  const _MealLogDialog({
    required this.repository,
    this.initialFoodId,
    this.initialFoodName,
    this.initialRecipeId,
    this.initialRecipeName,
  });

  final NutritionTrackingRepository repository;
  final String? initialFoodId;
  final String? initialFoodName;
  final String? initialRecipeId;
  final String? initialRecipeName;

  @override
  State<_MealLogDialog> createState() => _MealLogDialogState();
}

class _MealLogDialogState extends State<_MealLogDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _keywordController;
  late String _sourceType;
  String _mealType = 'breakfast';
  List<CatalogItem> _items = const [];
  String? _selectedId;
  String? _loadError;
  bool _loadingItems = false;
  int _loadRequest = 0;

  bool get _isCatalogLocked =>
      widget.initialFoodId != null || widget.initialRecipeId != null;

  bool get _isCustomDish =>
      !_isCatalogLocked && widget.initialFoodName?.trim().isNotEmpty == true;

  bool get _canSearch => !_isCatalogLocked && !_isCustomDish;

  @override
  void initState() {
    super.initState();
    _sourceType = widget.initialRecipeId != null ? 'recipe' : 'food';
    _selectedId = widget.initialFoodId ?? widget.initialRecipeId;
    _quantityController = TextEditingController(text: '100');
    _keywordController = TextEditingController(
      text: widget.initialFoodName ?? widget.initialRecipeName ?? '',
    );

    if (_canSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadItems();
      });
    }
  }

  @override
  void dispose() {
    _loadRequest++;
    _quantityController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final request = ++_loadRequest;
    final requestedSource = _sourceType;
    setState(() {
      _loadingItems = true;
      _loadError = null;
    });

    try {
      final keyword = _keywordController.text.trim();
      final loaded = requestedSource == 'food'
          ? await widget.repository.getFoods(
              keyword: keyword.isEmpty ? null : keyword,
            )
          : await widget.repository.getRecipes(
              keyword: keyword.isEmpty ? null : keyword,
            );
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _items = loaded;
        _selectedId = loaded.isEmpty ? null : loaded.first.id;
      });
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _items = const [];
        _selectedId = null;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && request == _loadRequest) {
        setState(() => _loadingItems = false);
      }
    }
  }

  void _confirm() {
    final parsedQuantity = double.tryParse(_quantityController.text.trim());
    Navigator.pop(
      context,
      _MealLogDraft(
        sourceType: _sourceType,
        mealType: _mealType,
        quantity: parsedQuantity != null && parsedQuantity > 0
            ? parsedQuantity
            : 100,
        keyword: _keywordController.text.trim(),
        selectedId: _selectedId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ghi vào nhật ký'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isCustomDish)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Món: ${widget.initialFoodName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            else if (widget.initialFoodId != null &&
                widget.initialFoodName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Món: ${widget.initialFoodName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            else if (widget.initialRecipeId != null &&
                widget.initialRecipeName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Công thức: ${widget.initialRecipeName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            if (!_isCustomDish)
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Nguồn'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sourceType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'food', child: Text('Món ăn')),
                      DropdownMenuItem(
                        value: 'recipe',
                        child: Text('Công thức'),
                      ),
                    ],
                    onChanged: _isCatalogLocked
                        ? null
                        : (value) async {
                            if (value == null || value == _sourceType) return;
                            setState(() {
                              _sourceType = value;
                              _selectedId = null;
                              _items = const [];
                            });
                            await _loadItems();
                          },
                  ),
                ),
              ),
            if (_canSearch) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _keywordController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadItems(),
                decoration: const InputDecoration(
                  labelText: 'Tìm kiếm',
                  hintText: 'Nhập từ khóa',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loadingItems ? null : _loadItems,
                  child: const Text('Tải danh sách'),
                ),
              ),
            ],
            if (_loadingItems)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            else if (_canSearch && _items.isNotEmpty)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: _sourceType == 'food'
                      ? 'Chọn món'
                      : 'Chọn công thức',
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedId,
                    isExpanded: true,
                    items: _items
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedId = value),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Loại bữa'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _mealType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'breakfast',
                      child: Text('Bữa sáng'),
                    ),
                    DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                    DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                    DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _mealType = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _sourceType == 'recipe'
                    ? 'Phần ăn (100 = 1 khẩu phần)'
                    : 'Khối lượng (gram)',
                hintText: _sourceType == 'recipe' ? 'Ví dụ: 100' : 'Ví dụ: 150',
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
        ElevatedButton(onPressed: _confirm, child: const Text('Ghi')),
      ],
    );
  }
}
