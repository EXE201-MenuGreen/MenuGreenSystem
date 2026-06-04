import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/food_models.dart';

Future<FoodSearchFilters?> showDiscoverFoodFiltersSheet(
  BuildContext context, {
  required FoodSearchFilters initial,
}) {
  return showModalBottomSheet<FoodSearchFilters>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _DiscoverFoodFiltersSheet(initial: initial),
  );
}

class _DiscoverFoodFiltersSheet extends StatefulWidget {
  const _DiscoverFoodFiltersSheet({required this.initial});

  final FoodSearchFilters initial;

  @override
  State<_DiscoverFoodFiltersSheet> createState() => _DiscoverFoodFiltersSheetState();
}

class _DiscoverFoodFiltersSheetState extends State<_DiscoverFoodFiltersSheet> {
  late final TextEditingController _minCal;
  late final TextEditingController _maxCal;
  late final TextEditingController _maxPrice;
  late final TextEditingController _category;
  String? _proteinLevel;

  @override
  void initState() {
    super.initState();
    _minCal = TextEditingController(
      text: widget.initial.minCalories?.round().toString() ?? '',
    );
    _maxCal = TextEditingController(
      text: widget.initial.maxCalories?.round().toString() ?? '',
    );
    _maxPrice = TextEditingController(
      text: widget.initial.maxPriceVnd?.toString() ?? '',
    );
    _category = TextEditingController(text: widget.initial.category ?? '');
    _proteinLevel = widget.initial.proteinLevel;
  }

  @override
  void dispose() {
    _minCal.dispose();
    _maxCal.dispose();
    _maxPrice.dispose();
    _category.dispose();
    super.dispose();
  }

  FoodSearchFilters _buildFilters() {
    double? parseDouble(String s) {
      final v = double.tryParse(s.trim());
      return v != null && v > 0 ? v : null;
    }

    int? parseInt(String s) {
      final v = int.tryParse(s.trim());
      return v != null && v > 0 ? v : null;
    }

    return FoodSearchFilters(
      minCalories: parseDouble(_minCal.text),
      maxCalories: parseDouble(_maxCal.text),
      proteinLevel: _proteinLevel,
      maxPriceVnd: parseInt(_maxPrice.text),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lọc món ăn',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories tối thiểu',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxCal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories tối đa',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Đạm',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _proteinLevel,
                isExpanded: true,
                hint: const Text('Tất cả'),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('Nhiều đạm (≥20g)')),
                  DropdownMenuItem(value: 'low', child: Text('Ít đạm (<20g)')),
                ],
                onChanged: (v) => setState(() => _proteinLevel = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxPrice,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Giá tối đa (VNĐ)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Nhóm món (category)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, const FoodSearchFilters()),
                child: const Text('Xóa lọc'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _buildFilters()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Áp dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
