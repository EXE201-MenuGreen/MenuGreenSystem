import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

/// Dialog thêm nhật ký bữa ăn — dùng từ Lịch sử hoặc Chi tiết món.
Future<bool> showMealLogSheet(
  BuildContext context, {
  String? initialFoodId,
  String? initialFoodName,
  String? initialRecipeId,
  String? initialRecipeName,
  DateTime? loggedAt,
}) async {
  final lockedToRecipe = initialRecipeId != null;
  String sourceType = lockedToRecipe ? 'recipe' : 'food';
  String mealType = 'breakfast';
  final quantityController = TextEditingController(text: '100');
  final keywordController = TextEditingController(
    text: initialFoodName ?? '',
  );
  final repository = NutritionTrackingRepository();
  List<CatalogItem> items = [];
  String? selectedId = initialFoodId ?? initialRecipeId;
  bool loadingItems = false;

  Future<void> loadItems(void Function(void Function()) setModalState) async {
    setModalState(() => loadingItems = true);
    final keyword = keywordController.text.trim();
    final loaded = sourceType == 'food'
        ? await repository.getFoods(keyword: keyword.isEmpty ? null : keyword)
        : await repository.getRecipes(keyword: keyword.isEmpty ? null : keyword);
    setModalState(() {
      items = loaded;
      if (selectedId != null && !items.any((e) => e.id == selectedId)) {
        selectedId = items.isNotEmpty ? items.first.id : null;
      } else if (selectedId == null && initialFoodId != null) {
        selectedId = initialFoodId;
      }
      loadingItems = false;
    });
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        if ((initialFoodId != null || initialRecipeId != null) &&
            items.isEmpty &&
            !loadingItems) {
          WidgetsBinding.instance.addPostFrameCallback((_) => loadItems(setModalState));
        }
        return AlertDialog(
          title: const Text('Ghi vào nhật ký'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (initialFoodId != null && initialFoodName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Món: $initialFoodName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (initialRecipeId != null && initialRecipeName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Công thức: $initialRecipeName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Nguồn'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sourceType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'food', child: Text('Món ăn')),
                        DropdownMenuItem(value: 'recipe', child: Text('Công thức')),
                      ],
                      onChanged: initialFoodId != null || initialRecipeId != null
                          ? null
                          : (value) {
                              if (value == null) return;
                              setModalState(() {
                                sourceType = value;
                                selectedId = null;
                                items = [];
                              });
                              loadItems(setModalState);
                            },
                    ),
                  ),
                ),
                if (initialFoodId == null && initialRecipeId == null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: keywordController,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm',
                      hintText: 'Nhập từ khóa',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => loadItems(setModalState),
                      child: const Text('Tải danh sách'),
                    ),
                  ),
                ],
                if (loadingItems)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else if (initialFoodId == null && initialRecipeId == null)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: sourceType == 'food' ? 'Chọn món' : 'Chọn công thức',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedId,
                        isExpanded: true,
                        items: items
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(e.name, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setModalState(() => selectedId = value),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Loại bữa'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: mealType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                        DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                        DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                        DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => mealType = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: sourceType == 'recipe'
                        ? 'Phần ăn (100 = 1 khẩu phần)'
                        : 'Khối lượng (gram)',
                    hintText: sourceType == 'recipe' ? 'Ví dụ: 100' : 'Ví dụ: 150',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ghi')),
          ],
        );
      },
    ),
  );

  if (confirmed != true) return false;

  final quantity = double.tryParse(quantityController.text.trim());
  final foodId = initialFoodId ?? (initialRecipeId == null && sourceType == 'food' ? selectedId : null);
  final recipeId = initialRecipeId ?? (initialFoodId == null && sourceType == 'recipe' ? selectedId : null);

  if ((foodId == null || foodId.isEmpty) && (recipeId == null || recipeId.isEmpty)) {
    return false;
  }
  if (quantity == null || quantity <= 0) return false;

  final at = loggedAt ?? DateTime.now();
  return repository.createMealLog(
    foodId: foodId,
    recipeId: recipeId,
    mealType: mealType,
    quantityG: quantity,
    loggedAt: at,
  );
}
