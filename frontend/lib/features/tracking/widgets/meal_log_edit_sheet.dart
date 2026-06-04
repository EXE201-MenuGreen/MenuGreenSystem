import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

/// Dialog sửa nhật ký bữa ăn đã ghi.
Future<bool> showMealLogEditSheet(
  BuildContext context, {
  required MealLogItem meal,
  DateTime? selectedDate,
}) async {
  final repository = NutritionTrackingRepository();
  var mealType = meal.mealType;
  final quantityController = TextEditingController(
    text: meal.quantityG.toStringAsFixed(0),
  );
  final notesController = TextEditingController(text: meal.notes ?? '');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) => AlertDialog(
        title: const Text('Sửa nhật ký bữa ăn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Loại bữa'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _normalizeMealType(mealType),
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
                  labelText: meal.isRecipe ? 'Phần ăn (100 = 1 khẩu phần)' : 'Khối lượng (gram)',
                  hintText: meal.isRecipe ? 'Ví dụ: 100' : 'Ví dụ: 150',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return false;

  final quantity = double.tryParse(quantityController.text.trim());
  if (quantity == null || quantity <= 0) return false;

  final foodId = meal.foodId;
  final recipeId = meal.recipeId;
  if ((foodId == null || foodId.isEmpty) && (recipeId == null || recipeId.isEmpty)) {
    return false;
  }

  final notesText = notesController.text.trim();
  final loggedAt = meal.loggedAt ??
      (selectedDate != null
          ? DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              DateTime.now().hour,
              DateTime.now().minute,
            )
          : DateTime.now());

  return repository.updateMealLog(
    meal.id,
    foodId: foodId,
    recipeId: recipeId,
    mealType: mealType,
    quantityG: quantity,
    notes: notesText.isEmpty ? null : notesText,
    loggedAt: loggedAt,
  );
}

String _normalizeMealType(String mealType) {
  switch (mealType.trim().toLowerCase()) {
    case 'breakfast':
    case 'bữa sáng':
      return 'breakfast';
    case 'lunch':
    case 'bữa trưa':
      return 'lunch';
    case 'dinner':
    case 'bữa tối':
      return 'dinner';
    default:
      return 'snack';
  }
}
