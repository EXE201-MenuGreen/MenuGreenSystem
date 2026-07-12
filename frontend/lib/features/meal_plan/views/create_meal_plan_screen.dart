import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/models/food_models.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';

/// Screen tạo/sửa meal plan - 4-step wizard
/// Dùng chung cho cả tạo mới và sửa
class CreateMealPlanScreen extends StatefulWidget {
  const CreateMealPlanScreen({
    super.key,
    this.existingPlan,
  });

  /// Plan hiện có - nếu null thì là tạo mới
  final MealPlanDetail? existingPlan;

  @override
  State<CreateMealPlanScreen> createState() => _CreateMealPlanScreenState();
}

class _CreateMealPlanScreenState extends State<CreateMealPlanScreen> {
  final _pageController = PageController();
  final _titleController = TextEditingController();
  final _caloriesController = TextEditingController(text: '2000');

  bool get _isEditMode => widget.existingPlan != null;

  int _currentStep = 0;
  PlanType _selectedPlanType = PlanType.weekly;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _targetCalories = 2000;
  int _proteinPercent = 25;
  int _carbsPercent = 40;
  int _fatPercent = 35;
  bool _isLoading = false;

  // Step 3: Selected meals
  final Map<MealType, List<_SelectedFood>> _selectedMeals = {
    MealType.breakfast: [],
    MealType.lunch: [],
    MealType.dinner: [],
    MealType.snack: [],
  };

  @override
  void initState() {
    super.initState();
    _endDate = _startDate.add(const Duration(days: 6));

    if (_isEditMode) {
      _loadExistingPlan();
    }
  }

  void _loadExistingPlan() {
    final plan = widget.existingPlan!;

    _titleController.text = plan.title;
    _selectedPlanType = PlanType.fromString(plan.planType);
    _startDate = plan.startDate ?? DateTime.now();
    _endDate = plan.endDate;
    _targetCalories = plan.targetCalories ?? 2000;
    _caloriesController.text = _targetCalories.toString();

    if (plan.targetCalories != null && plan.targetCalories! > 0) {
      final totalCal = plan.targetCalories!;
      _proteinPercent = _calculatePercent(plan.targetProtein ?? 0, totalCal, 4);
      _carbsPercent = _calculatePercent(plan.targetCarbs ?? 0, totalCal, 4);
      _fatPercent = 100 - _proteinPercent - _carbsPercent;

      if (_fatPercent < 10) _fatPercent = 35;
      if (_proteinPercent < 10) _proteinPercent = 25;
      if (_carbsPercent < 10) _carbsPercent = 40;
    }

    // Load existing items
    for (final item in plan.items) {
      final mealType = MealType.fromString(item.mealType);
      if (_selectedMeals.containsKey(mealType)) {
        _selectedMeals[mealType]!.add(_SelectedFood(
          id: item.foodId ?? item.recipeId ?? '',
          name: item.foodName ?? item.recipeName ?? 'Unknown',
          calories: item.targetCalories ?? 0,
          isFood: item.foodId != null,
        ));
      }
    }
  }

  int _calculatePercent(int grams, int totalCalories, int caloriesPerGram) {
    if (totalCalories == 0) return 25;
    final calories = grams * caloriesPerGram;
    return ((calories / totalCalories) * 100).round();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Sửa kế hoạch' : 'Tạo kế hoạch mới'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildStepIndicator(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1BasicInfo(),
          _buildStep2Nutrition(),
          _buildStep3SelectMeals(),
          _buildStep4Confirm(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Thông tin', 'Dinh dưỡng', 'Chọn món', 'Xác nhận'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isActive = index <= _currentStep;
            return Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.progressBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 30,
                    height: 2,
                    color: index < _currentStep
                        ? AppColors.primary
                        : AppColors.progressBackground,
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          labels[_currentStep],
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ==================== STEP 1: Basic Info ====================

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tên kế hoạch',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'VD: Kế hoạch giảm cân 2 tuần',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Loại kế hoạch',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...PlanType.values.map((type) => RadioListTile<PlanType>(
            title: Text(_planTypeLabel(type)),
            value: type,
            // ignore: deprecated_member_use
            groupValue: _selectedPlanType,
            // ignore: deprecated_member_use
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPlanType = value;
                  _updateDates();
                });
              }
            },
          )),
          const SizedBox(height: 24),

          const Text(
            'Thời gian',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(isStart: true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_formatDate(_startDate)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('đến'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(isStart: false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate != null ? _formatDate(_endDate!) : 'Chọn'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goToStep(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Tiếp theo'),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: Nutrition ====================

  Widget _buildStep2Nutrition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mục tiêu calories',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _caloriesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              suffixText: 'kcal',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _targetCalories = int.tryParse(value) ?? 2000;
              });
            },
          ),
          const SizedBox(height: 24),

          const Text(
            'Tỷ lệ Macros',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          _buildMacroSlider('Protein', _proteinPercent, Colors.blue, (value) {
            setState(() {
              _proteinPercent = value;
              _balanceMacros('protein', value);
            });
          }),
          const SizedBox(height: 16),
          _buildMacroSlider('Carbs', _carbsPercent, Colors.orange, (value) {
            setState(() {
              _carbsPercent = value;
              _balanceMacros('carbs', value);
            });
          }),
          const SizedBox(height: 16),
          _buildMacroSlider('Fat', _fatPercent, Colors.purple, (value) {
            setState(() {
              _fatPercent = value;
              _balanceMacros('fat', value);
            });
          }),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToStep(0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _goToStep(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Tiếp theo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STEP 3: Select Meals ====================

  Widget _buildStep3SelectMeals() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '🍳 Sáng'),
              Tab(text: '🍱 Trưa'),
              Tab(text: '🍽️ Tối'),
              Tab(text: '🍿 Phụ'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMealTab(MealType.breakfast),
                _buildMealTab(MealType.lunch),
                _buildMealTab(MealType.dinner),
                _buildMealTab(MealType.snack),
              ],
            ),
          ),
          _buildStep3Navigation(),
        ],
      ),
    );
  }

  Widget _buildMealTab(MealType mealType) {
    final meals = _selectedMeals[mealType] ?? [];
    final mealTarget = mealType.getCaloriesTarget(_targetCalories);

    return Column(
      children: [
        // Summary calories for this meal
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${mealType.emoji} ${mealType.labelVi}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_calculateMealCalories(meals)} / $mealTarget kcal',
                style: TextStyle(
                  color: _calculateMealCalories(meals) > mealTarget
                      ? Colors.red
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Selected meals list
        if (meals.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                final meal = meals[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      meal.isFood ? Icons.restaurant : Icons.menu_book,
                      color: AppColors.primary,
                    ),
                    title: Text(meal.name),
                    subtitle: Text('${meal.calories} kcal'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedMeals[mealType]!.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Chưa chọn món nào\nNhấn nút bên dưới để thêm',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),

        // Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showFoodPicker(mealType),
              icon: const Icon(Icons.add),
              label: const Text('Thêm món ăn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Navigation() {
    final totalMeals = _selectedMeals.values.fold<int>(0, (sum, list) => sum + list.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _goToStep(1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Quay lại'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _goToStep(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(totalMeals > 0
                  ? 'Tiếp theo ($totalMeals món)'
                  : 'Bỏ qua (sẽ thêm sau)'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFoodPicker(MealType mealType) async {
    final result = await showModalBottomSheet<_SelectedFood>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FoodPickerSheet(
        mealType: mealType,
        targetCalories: mealType.getCaloriesTarget(_targetCalories),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedMeals[mealType]!.add(result);
      });
    }
  }

  int _calculateMealCalories(List<_SelectedFood> meals) {
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  // ==================== STEP 4: Confirm ====================

  Widget _buildStep4Confirm() {
    final proteinG = (_targetCalories * _proteinPercent / 100 / 4).round();
    final carbsG = (_targetCalories * _carbsPercent / 100 / 4).round();
    final fatG = (_targetCalories * _fatPercent / 100 / 9).round();
    final totalSelectedMeals = _selectedMeals.values.fold<int>(0, (sum, list) => sum + list.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin kế hoạch',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Tên', _titleController.text.isEmpty ? 'Kế hoạch mới' : _titleController.text),
                  _buildSummaryRow('Loại', _planTypeLabel(_selectedPlanType)),
                  _buildSummaryRow('Thời gian', '${_formatDate(_startDate)} - ${_endDate != null ? _formatDate(_endDate!) : "..."}'),
                  _buildSummaryRow('Số món ăn', '$totalSelectedMeals món'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nutrition card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mục tiêu dinh dưỡng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Calories', '$_targetCalories kcal/ngày'),
                  _buildSummaryRow('Protein', '$proteinG g ($_proteinPercent%)'),
                  _buildSummaryRow('Carbs', '$carbsG g ($_carbsPercent%)'),
                  _buildSummaryRow('Fat', '$fatG g ($_fatPercent%)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Meals summary
          if (totalSelectedMeals > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh sách món ăn',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...MealType.values.map((type) {
                      final meals = _selectedMeals[type] ?? [];
                      if (meals.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${type.emoji} ${type.labelVi}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          ...meals.map((m) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• ${m.name}'),
                                Text('${m.calories} kcal'),
                              ],
                            ),
                          )),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Navigation
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToStep(2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isEditMode ? _updatePlan : _createPlan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isEditMode ? 'Lưu thay đổi' : 'Tạo kế hoạch'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMacroSlider(String label, int value, Color color, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$value%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 10,
          max: 50,
          divisions: 8,
          activeColor: color,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  String _planTypeLabel(PlanType type) {
    switch (type) {
      case PlanType.daily:
        return 'Theo ngày';
      case PlanType.weekly:
        return 'Theo tuần';
      case PlanType.custom:
        return 'Tùy chỉnh';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _updateDates() {
    switch (_selectedPlanType) {
      case PlanType.daily:
        _endDate = _startDate;
        break;
      case PlanType.weekly:
        _endDate = _startDate.add(const Duration(days: 6));
        break;
      case PlanType.custom:
        _endDate = null;
        break;
    }
  }

  void _balanceMacros(String changed, int newValue) {
    final total = _proteinPercent + _carbsPercent + _fatPercent;
    if (total > 100) {
      final excess = total - 100;
      if (changed == 'protein' && _carbsPercent >= excess) {
        _carbsPercent -= excess;
      } else if (changed == 'carbs' && _proteinPercent >= excess) {
        _proteinPercent -= excess;
      } else if (changed == 'fat') {
        if (_proteinPercent >= excess) {
          _proteinPercent -= excess;
        } else {
          _carbsPercent -= (excess - _proteinPercent);
          _proteinPercent = 0;
        }
      }
    }
  }

  Future<void> _selectDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          _updateDates();
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _goToStep(int step) {
    if (step > _currentStep) {
      if (_currentStep == 0 && _titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập tên kế hoạch'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_currentStep == 1) {
        final calories = int.tryParse(_caloriesController.text) ?? 0;
        if (calories < 500 || calories > 10000) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calories phải từ 500 đến 10,000 kcal'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }
    }

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  // ==================== Submit Logic ====================

  Future<void> _createPlan() async {
    setState(() => _isLoading = true);

    try {
      final totalMeals = _selectedMeals.values.fold<int>(0, (sum, list) => sum + list.length);

      if (totalMeals > 0) {
        // Create with items
        final items = <CreateItemRequest>[];
        for (final entry in _selectedMeals.entries) {
          for (final meal in entry.value) {
            items.add(CreateItemRequest(
              mealType: entry.key.value,
              foodId: meal.isFood ? meal.id : null,
              recipeId: meal.isFood ? null : meal.id,
              targetCalories: meal.calories,
            ));
          }
        }

        final request = CreatePlanWithItemsRequest(
          title: _titleController.text.isEmpty ? 'Kế hoạch mới' : _titleController.text,
          planType: _selectedPlanType.value,
          startDate: _startDate,
          endDate: _endDate,
          targetCalories: _targetCalories,
          items: items,
        );

        final plan = await context.read<MealPlanProvider>().createPlanWithItems(request);

        if (mounted) {
          if (plan != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo kế hoạch thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            // Quay về danh sách thay vì vào chi tiết
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            final error = context.read<MealPlanProvider>().error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Không thể tạo kế hoạch'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Create empty plan
        final request = CreateEmptyPlanRequest(
          title: _titleController.text.isEmpty ? 'Kế hoạch mới' : _titleController.text,
          planType: _selectedPlanType.value,
          startDate: _startDate,
          endDate: _endDate,
          targetCalories: _targetCalories,
        );

        final plan = await context.read<MealPlanProvider>().createEmptyPlan(request);

        if (mounted) {
          if (plan != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo kế hoạch thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            // Quay về danh sách thay vì vào chi tiết
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            final error = context.read<MealPlanProvider>().error;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Không thể tạo kế hoạch'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Lỗi tạo kế hoạch';
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('title')) {
          errorMsg = 'Tên kế hoạch không hợp lệ';
        } else if (errorStr.contains('date') || errorStr.contains('time')) {
          errorMsg = 'Ngày tháng không hợp lệ';
        } else if (errorStr.contains('calories') || errorStr.contains('kcal')) {
          errorMsg = 'Calories không hợp lệ';
        } else if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          errorMsg = 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại';
        } else if (errorStr.contains('500') || errorStr.contains('server')) {
          errorMsg = 'Lỗi server, vui lòng thử lại sau';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePlan() async {
    setState(() => _isLoading = true);

    try {
      final request = CreatePlanRequest(
        title: _titleController.text.isEmpty ? 'Kế hoạch mới' : _titleController.text,
        planType: _selectedPlanType.value,
        startDate: _startDate,
        endDate: _endDate,
        targetCalories: _targetCalories,
        isActive: true,
      );

      final plan = await context.read<MealPlanProvider>().updatePlan(
        widget.existingPlan!.id,
        request,
      );

      if (mounted) {
        if (plan != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật kế hoạch thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final error = context.read<MealPlanProvider>().error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Không thể cập nhật kế hoạch'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Lỗi cập nhật kế hoạch';
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
          errorMsg = 'Phiên đăng nhập hết hạn, vui lòng đăng nhập lại';
        } else if (errorStr.contains('500') || errorStr.contains('server')) {
          errorMsg = 'Lỗi server, vui lòng thử lại sau';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ==================== Food Picker Sheet ====================

class _SelectedFood {
  final String id;
  final String name;
  final int calories;
  final bool isFood;

  _SelectedFood({
    required this.id,
    required this.name,
    required this.calories,
    required this.isFood,
  });
}

class _FoodPickerSheet extends StatefulWidget {
  final MealType mealType;
  final int targetCalories;

  const _FoodPickerSheet({
    required this.mealType,
    required this.targetCalories,
  });

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _foodRepository = FoodDiscoveryRepository();

  List<FoodItem> _foods = [];
  List<RecipeItem> _recipes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final foods = await _foodRepository.searchFoods();
      final recipes = await _foodRepository.searchRecipes();
      if (mounted) {
        setState(() {
          _foods = foods;
          _recipes = recipes;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final foods = await _foodRepository.searchFoods(keyword: query);
      final recipes = await _foodRepository.searchRecipes(keyword: query);
      if (mounted) {
        setState(() {
          _foods = foods;
          _recipes = recipes;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chọn món cho ${widget.mealType.emoji} ${widget.mealType.labelVi}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mục tiêu: ~${widget.targetCalories} kcal',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm món ăn...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: _search,
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '🍽️ Thực phẩm'),
                Tab(text: '📖 Công thức'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFoodList(_foods, scrollController),
                  _buildFoodList(_recipes, scrollController),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFoodList<T>(List<T> items, ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả'),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String id;
        final String name;
        final int calories;

        if (item is FoodItem) {
          id = item.id;
          name = item.nameVi;
          calories = (item.caloriesKcal ?? 0).round();
        } else if (item is RecipeItem) {
          id = item.id;
          name = item.title;
          calories = item.totalCalories;
        } else {
          return const SizedBox.shrink();
        }

        final isOverTarget = calories > widget.targetCalories * 1.5;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isOverTarget ? Colors.red.shade100 : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                item is FoodItem ? Icons.restaurant : Icons.menu_book,
                color: isOverTarget ? Colors.red : AppColors.primary,
              ),
            ),
            title: Text(name),
            subtitle: Text('$calories kcal'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _SelectedFood(
                    id: id,
                    name: name,
                    calories: calories,
                    isFood: item is FoodItem,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Chọn'),
            ),
          ),
        );
      },
    );
  }
}
