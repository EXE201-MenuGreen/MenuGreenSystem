import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';
import '../providers/meal_plan_provider.dart';
import 'meal_plan_detail_screen.dart';

/// Screen tạo/sửa meal plan - 3-step wizard
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

  @override
  void initState() {
    super.initState();
    _endDate = _startDate.add(const Duration(days: 6));
    
    // Load existing plan data if editing
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
    
    // Calculate macro percentages from targets
    if (plan.targetCalories != null && plan.targetCalories! > 0) {
      final totalCal = plan.targetCalories!;
      _proteinPercent = _calculatePercent(plan.targetProtein ?? 0, totalCal, 4);
      _carbsPercent = _calculatePercent(plan.targetCarbs ?? 0, totalCal, 4);
      _fatPercent = 100 - _proteinPercent - _carbsPercent;
      
      // Ensure valid percentages
      if (_fatPercent < 10) _fatPercent = 35;
      if (_proteinPercent < 10) _proteinPercent = 25;
      if (_carbsPercent < 10) _carbsPercent = 40;
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
          _buildStep3Confirm(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
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
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: index < _currentStep
                    ? AppColors.primary
                    : AppColors.progressBackground,
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStep1BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
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

          // Plan type
          const Text(
            'Loại kế hoạch',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...PlanType.values.map((type) => RadioListTile<PlanType>(
            title: Text(_planTypeLabel(type)),
            value: type,
            groupValue: _selectedPlanType,
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

          // Date range
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

          // Next button
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

  Widget _buildStep2Nutrition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calories
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

          // Macro ratios
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

          // Navigation
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

  Widget _buildStep3Confirm() {
    final proteinG = (_targetCalories * 0.25 / 4).round();
    final carbsG = (_targetCalories * 0.40 / 4).round();
    final fatG = (_targetCalories * 0.35 / 9).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiết kế hoạch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Tên', _titleController.text.isEmpty ? 'Kế hoạch mới' : _titleController.text),
                  _buildSummaryRow('Loại', _planTypeLabel(_selectedPlanType)),
                  _buildSummaryRow('Thời gian', '${_formatDate(_startDate)} - ${_endDate != null ? _formatDate(_endDate!) : "..."}'),
                  const Divider(),
                  const Text(
                    'Mục tiêu dinh dưỡng:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Calories', '$_targetCalories kcal/ngày'),
                  _buildSummaryRow('Protein', '$proteinG g ($_proteinPercent%)'),
                  _buildSummaryRow('Carbs', '$carbsG g ($_carbsPercent%)'),
                  _buildSummaryRow('Fat', '$fatG g ($_fatPercent%)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? 'Thay đổi sẽ được lưu ngay lập tức'
                        : 'Bạn có thể thêm bữa ăn sau khi tạo kế hoạch',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Navigation
          Row(
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
                  onPressed: _isLoading ? null : (_isEditMode ? _updatePlan : _createPlan),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  Future<void> _createPlan() async {
    setState(() => _isLoading = true);

    try {
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
            const SnackBar(content: Text('Tạo kế hoạch thành công! Bạn có thể thêm bữa ăn ngay bây giờ.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MealPlanDetailScreen(planId: plan.id),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo kế hoạch')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo kế hoạch: $e')),
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
            const SnackBar(content: Text('Cập nhật kế hoạch thành công!')),
          );
          // Reload detail screen and pop back
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<MealPlanProvider>().error ?? 'Không thể cập nhật kế hoạch')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật kế hoạch: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
