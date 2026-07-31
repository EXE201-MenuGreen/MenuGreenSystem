import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/repositories/food_discovery_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../coach_pt.dart';

/// Coach-side create-meal-plan screen with a modern 3-step wizard UI matching Gym Goals layout.
class CoachCreateMealPlanScreen extends StatefulWidget {
  const CoachCreateMealPlanScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  final String clientId;
  final String clientName;

  @override
  State<CoachCreateMealPlanScreen> createState() =>
      _CoachCreateMealPlanScreenState();
}

class _CoachCreateMealPlanScreenState extends State<CoachCreateMealPlanScreen> {
  int _step = 0;
  final DateTime _createdAt = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  String _planType = 'weekly';
  String _goalMode = 'maintain'; // 'cut', 'maintain', 'bulk', 'recomp'
  bool _isDayTraining = true;
  DateTime? _singleDate = DateTime.now();
  int? _targetCalories;
  int? _minCalories;
  int? _maxCalories;
  final _targetCaloriesController = TextEditingController();
  final _minCaloriesController = TextEditingController();
  final _maxCaloriesController = TextEditingController();
  final _minProteinController = TextEditingController(text: '50');
  final _maxProteinController = TextEditingController(text: '100');
  final _notesController = TextEditingController();
  String _configSource = 'profile';
  List<Map<String, dynamic>> _suggestions = const [];
  bool _loadingSuggestions = false;
  String? _suggestionsError;
  final Map<String, List<_DraftItemDraft>> _itemsByMeal = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': [],
  };
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadClientConfig());
  }

  @override
  void dispose() {
    _targetCaloriesController.dispose();
    _minCaloriesController.dispose();
    _maxCaloriesController.dispose();
    _minProteinController.dispose();
    _maxProteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isDaily => _planType == 'daily';
  bool get _isMonthly => _planType == 'monthly';

  String _defaultTitle() {
    final (start, end) = _resolvedRange;
    final typeLabel = switch (_planType) {
      'daily' => 'Ngày',
      'monthly' => 'Tháng',
      _ => 'Tuần',
    };
    return 'Lộ trình $typeLabel ${_fmt(start)}'
        '${start == end ? '' : ' - ${_fmt(end)}'}';
  }

  (DateTime, DateTime) get _resolvedRange {
    if (_isDaily) {
      final selected = _singleDate ?? DateTime.now();
      final date = DateTime(selected.year, selected.month, selected.day);
      return (date, date);
    }
    if (_isMonthly) {
      final selected = _singleDate ?? DateTime.now();
      return (
        DateTime(selected.year, selected.month, 1),
        DateTime(selected.year, selected.month + 1, 0),
      );
    }
    final selected = _singleDate ?? DateTime.now();
    final date = DateTime(selected.year, selected.month, selected.day);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return (monday, monday.add(const Duration(days: 6)));
  }

  List<DateTime> get _planDates {
    final (start, end) = _resolvedRange;
    final count = end.difference(start).inDays + 1;
    return List.generate(count, (index) => start.add(Duration(days: index)));
  }

  Future<void> _pickDate() async {
    final initial = _singleDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: initial,
    );
    if (picked != null) {
      setState(() => _singleDate = picked);
      await _loadClientConfig();
    }
  }

  Future<void> _loadClientConfig() async {
    final selectedDate = _singleDate;
    if (selectedDate == null) return;
    try {
      final config = await context
          .read<CoachMealPlanProvider>()
          .loadClientGymConfig(selectedDate);
      if (!mounted || config == null) return;
      final target = _mapInt(config, 'targetCalories');
      final min = _mapInt(config, 'minCalories');
      final max = _mapInt(config, 'maxCalories');
      final resolvedTarget = target ?? 1500;
      final resolvedMin = min ?? 500;
      final resolvedMax = max ?? resolvedTarget;
      setState(() {
        _targetCalories = resolvedTarget;
        _minCalories = resolvedMin;
        _maxCalories = resolvedMax;
        _configSource = _mapString(config, 'scope');
        _targetCaloriesController.text = resolvedTarget.toString();
        _minCaloriesController.text = resolvedMin.toString();
        _maxCaloriesController.text = resolvedMax.toString();
      });
    } catch (_) {}
  }

  bool get _canNext {
    if (_step == 0) {
      final validBounds =
          _minCalories == null ||
          _maxCalories == null ||
          _minCalories! <= _maxCalories!;
      return _singleDate != null &&
          _targetCalories != null &&
          _targetCalories! > 0 &&
          validBounds;
    }
    if (_step == 1) {
      return _itemsByMeal.values.any((items) => items.isNotEmpty);
    }
    return true;
  }

  Future<void> _saveDraft() async {
    setState(() => _submitting = true);
    final items = _itemsByMeal.values
        .expand((l) => l)
        .map(
          (d) => ClientMealPlanItemPayload(
            mealType: d.mealType,
            foodId: d.foodId,
            recipeId: d.recipeId,
            plannedDate: d.plannedDate,
            scheduledTime: d.scheduledTime,
            targetCalories: d.targetCalories,
          ),
        )
        .toList();

    final (startDate, endDate) = _resolvedRange;

    final payload = ClientMealPlanPayload(
      title: _defaultTitle(),
      planType: _planType,
      startDate: startDate,
      endDate: endDate,
      targetCalories: _targetCalories,
      minCalories: _minCalories,
      maxCalories: _maxCalories,
      coachNotes: _notesController.text.trim(),
      items: items,
    );

    final ok = await context.read<CoachMealPlanProvider>().createPlan(payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cấu hình và danh sách món thành công!'),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu bản nháp thất bại. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: Text(
          'Tạo lộ trình - ${widget.clientName}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Header Bar
          _StepProgressHeader(
            currentStep: _step,
            onStepTapped: (step) {
              if (step < _step) {
                setState(() => _step = step);
              }
            },
          ),

          // Main Step Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_step == 0) _buildStep1Configuration(),
                if (_step == 1) _buildStep2MealSelection(),
                if (_step == 2) _buildStep3Review(),
              ],
            ),
          ),

          // Bottom Action Navigation Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Quay lại'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: const Color(0xFF374151),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _step--),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _step == 2
                                    ? Icons.save_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                        label: Text(
                          _step == 2 ? 'Lưu bản nháp lộ trình' : 'Tiếp tục',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: !_canNext || _submitting
                            ? null
                            : () async {
                                if (_step == 0) {
                                  if (!(_formKey.currentState?.validate() ??
                                          false) ||
                                      !_canNext) {
                                    return;
                                  }
                                  setState(() => _step = 1);
                                  await _loadSuitableSuggestions();
                                } else if (_step == 1) {
                                  setState(() => _step = 2);
                                } else {
                                  await _saveDraft();
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 1: Cấu hình (Design matching Gym Goals Screen Image 2)
  // ===========================================================================
  Widget _buildStep1Configuration() {
    final (start, end) = _resolvedRange;
    final dateDisplay = _isMonthly
        ? 'Tháng: ${start.month.toString().padLeft(2, '0')}/${start.year}'
        : (_isDaily ? _fmt(start) : '${_fmt(start)} - ${_fmt(end)}');

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Chế độ & Thời gian (Goal Mode & Scope Selector)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chế độ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),

                // Choice Chips: Siết cơ / Giữ cân / Xả cơ / Giảm mỡ tăng cơ
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['cut', 'maintain', 'bulk', 'recomp']
                      .map(
                        (e) => ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_goalMode.toLowerCase() == e) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                _goalModeLabel(e),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _goalMode.toLowerCase() == e
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _goalMode.toLowerCase() == e
                                      ? AppColors.primary
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          selected: _goalMode.toLowerCase() == e,
                          onSelected: (_) => setState(() => _goalMode = e),
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          backgroundColor: const Color(0xFFF3F4F6),
                          side: BorderSide(
                            color: _goalMode.toLowerCase() == e
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Kỳ cấu hình Tab Bar (Ngày / Tuần / Tháng)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildScopeTab('daily', 'Ngày'),
                      _buildScopeTab('weekly', 'Tuần'),
                      _buildScopeTab('monthly', 'Tháng'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Selector Tile (Chọn ngày/tuần/tháng cấu hình)
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isMonthly
                                    ? 'Chọn tháng cấu hình'
                                    : (_isDaily
                                          ? 'Chọn ngày cấu hình'
                                          : 'Chọn tuần cấu hình'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateDisplay,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF111827),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Gymer Config Reference Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _configSource == 'profile'
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _configSource == 'profile'
                          ? const Color(0xFFFFEDD5)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: _configSource == 'profile'
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF047857),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _configSource == 'profile'
                              ? 'Gymer chưa có cấu hình riêng cho ngày này. PT hãy nhập thông số bên dưới.'
                              : 'Đang tham chiếu cấu hình ${_scopeLabel(_configSource)} của Gymer. PT có thể thay đổi trước khi gửi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _configSource == 'profile'
                                ? const Color(0xFFC2410C)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card 2: Cấu hình chi tiết... (Stepper Inputs)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isDaily
                      ? 'Cấu hình chi tiết ngày $dateDisplay'
                      : (_isMonthly
                            ? 'Cấu hình chi tiết tháng'
                            : 'Cấu hình chi tiết tuần'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),

                // Chế độ hoạt động: Nghỉ ngơi vs Tập luyện
                Row(
                  children: [
                    const Text(
                      'Chế độ hoạt động:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const Spacer(),
                    ChoiceChip(
                      label: const Text('Nghỉ ngơi'),
                      selected: !_isDayTraining,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _isDayTraining = false);
                        }
                      },
                      selectedColor: const Color(0xFFF3F4F6),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Tập luyện'),
                      selected: _isDayTraining,
                      showCheckmark: true,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _isDayTraining = true);
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Calo mục tiêu (kcal) Stepper Field
                _buildStepperField(
                  label: 'Calo mục tiêu (kcal)',
                  controller: _targetCaloriesController,
                  step: 50,
                  minValue: 0,
                  onChanged: (val) => setState(() => _targetCalories = val),
                ),
                const SizedBox(height: 14),

                // Calo tối thiểu & Calo tối đa Stepper Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildStepperField(
                        label: 'Calo tối thiểu',
                        controller: _minCaloriesController,
                        step: 50,
                        minValue: 0,
                        onChanged: (val) => setState(() => _minCalories = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStepperField(
                        label: 'Calo tối đa',
                        controller: _maxCaloriesController,
                        step: 50,
                        minValue: 0,
                        onChanged: (val) => setState(() => _maxCalories = val),
                      ),
                    ),
                  ],
                ),
                if (_minCalories != null &&
                    _maxCalories != null &&
                    _minCalories! > _maxCalories!) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Calo tối thiểu không được lớn hơn calo tối đa.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),

                // Protein tối thiểu (g) & Protein tối đa (g) Stepper Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildStepperField(
                        label: 'Protein tối thiểu (g)',
                        controller: _minProteinController,
                        step: 5,
                        minValue: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStepperField(
                        label: 'Protein tối đa (g)',
                        controller: _maxProteinController,
                        step: 5,
                        minValue: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ghi chú của PT cho Gymer
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú của PT cho Gymer',
                    hintText: 'Nhập ghi chú hoặc dặn dò cho Gymer...',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTab(String value, String label) {
    final active = _planType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (active) return;
          setState(() {
            _planType = value;
            _suggestions = const [];
            _suggestionsError = null;
            for (final items in _itemsByMeal.values) {
              items.clear();
            }
          });
          _loadClientConfig();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF374151),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperField({
    required String label,
    required TextEditingController controller,
    required int step,
    int? minValue,
    void Function(int)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  final val = int.tryParse(controller.text.trim()) ?? 0;
                  final newVal = val - step;
                  if (minValue == null || newVal >= minValue) {
                    controller.text = newVal.toString();
                    if (onChanged != null) onChanged(newVal);
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null && onChanged != null) {
                      onChanged(val);
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                onPressed: () {
                  final val = int.tryParse(controller.text.trim()) ?? 0;
                  final newVal = val + step;
                  controller.text = newVal.toString();
                  if (onChanged != null) onChanged(newVal);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _goalModeLabel(String mode) {
    return switch (mode.toLowerCase()) {
      'cut' => 'Siết cơ',
      'maintain' => 'Giữ cân',
      'bulk' => 'Xả cơ',
      'recomp' => 'Giảm mỡ tăng cơ',
      _ => 'Giữ cân',
    };
  }

  // ===========================================================================
  // Step 2: Chọn món
  // ===========================================================================
  Widget _buildStep2MealSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Suggestion Banner Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF135A37), Color(0xFF1A7A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A7A4A).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Món ăn phù hợp cấu hình',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Mục tiêu $_targetCalories kcal/ngày'
                          '${_minCalories == null ? '' : ' • từ $_minCalories kcal'}'
                          '${_maxCalories == null ? '' : ' • tối đa $_maxCalories kcal'}'
                          ' • protein ${_minProteinController.text.trim()}-'
                          '${_maxProteinController.text.trim()} g/ngày',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFD1FAE5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loadingSuggestions
                        ? null
                        : _loadSuitableSuggestions,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'Tải lại gợi ý',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loadingSuggestions
                      ? null
                      : _initializeFromSuggestions,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _itemsByMeal.values.any((items) => items.isNotEmpty)
                        ? 'Khởi tạo lại danh sách món'
                        : 'Khởi tạo lộ trình mới',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (_loadingSuggestions) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ] else if (_suggestionsError != null) ...[
          Center(
            child: Text(
              _suggestionsError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ] else if (_suggestions.isNotEmpty) ...[
          _SuggestionPreview(
            suggestions: _suggestions,
            onView: (suggestion) => _openItemDetail(
              _draftFromSuggestion(
                suggestion,
                mealType: 'snack',
                plannedDate: _resolvedRange.$1,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Meal Slots Accordions
        for (final mealType in const [
          (
            'breakfast',
            'Bữa sáng',
            Icons.wb_sunny_rounded,
            Color(0xFFFFFBEB),
            Color(0xFFB45309),
          ),
          (
            'lunch',
            'Bữa trưa',
            Icons.lunch_dining_rounded,
            Color(0xFFECFDF5),
            Color(0xFF047857),
          ),
          (
            'dinner',
            'Bữa tối',
            Icons.dark_mode_rounded,
            Color(0xFFEEF2FF),
            Color(0xFF4338CA),
          ),
          (
            'snack',
            'Bữa phụ',
            Icons.bakery_dining_rounded,
            Color(0xFFF3E8FF),
            Color(0xFF6B21A8),
          ),
        ])
          _MealPickerRow(
            mealType: mealType.$1,
            label: mealType.$2,
            icon: mealType.$3,
            bgColor: mealType.$4,
            textColor: mealType.$5,
            items: _itemsByMeal[mealType.$1]!,
            onAdd: () => _pickItemFor(mealType.$1),
            onRemove: (it) =>
                setState(() => _itemsByMeal[mealType.$1]!.remove(it)),
            onEdit: _editDraftItem,
            onReplace: (it) => _pickItemFor(mealType.$1, replacing: it),
            onView: _openItemDetail,
          ),
      ],
    );
  }

  // ===========================================================================
  // Step 3: Xem lại
  // ===========================================================================
  Widget _buildStep3Review() {
    int totalP = 0;
    int totalC = 0;
    int totalF = 0;
    int totalCal = 0;
    int totalItems = 0;
    for (final list in _itemsByMeal.values) {
      for (final item in list) {
        totalCal += item.targetCalories ?? 0;
        totalP += (item.proteinG ?? 0).round();
        totalC += (item.carbsG ?? 0).round();
        totalF += (item.fatG ?? 0).round();
        totalItems++;
      }
    }

    final dayCount = _planDates.length;
    final averageCalories = dayCount == 0 ? 0 : (totalCal / dayCount).round();
    final averageProtein = dayCount == 0 ? 0 : (totalP / dayCount).round();
    final averageCarbs = dayCount == 0 ? 0 : (totalC / dayCount).round();
    final averageFat = dayCount == 0 ? 0 : (totalF / dayCount).round();

    final (start, end) = _resolvedRange;
    final typeLabel = switch (_planType) {
      'daily' => 'Hàng ngày',
      'monthly' => 'Hàng tháng',
      _ => 'Hàng tuần',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tổng quan cấu hình',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ReviewRow('Tên lộ trình', _defaultTitle()),
              _ReviewRow('Ngày khởi tạo', _fmt(_createdAt)),
              _ReviewRow('Chế độ', _goalModeLabel(_goalMode)),
              _ReviewRow('Loại lộ trình', typeLabel),
              _ReviewRow(
                'Thời gian',
                start == end ? _fmt(start) : '${_fmt(start)} - ${_fmt(end)}',
              ),
              _ReviewRow('Mục tiêu calo', '$_targetCalories kcal/ngày'),
              if (_minCalories != null || _maxCalories != null)
                _ReviewRow(
                  'Khoảng calo/món',
                  '${_minCalories ?? 0} - ${_maxCalories ?? 'không giới hạn'} kcal',
                ),
              _ReviewRow(
                'Khoảng protein',
                '${_minProteinController.text.trim()} - '
                    '${_maxProteinController.text.trim()} g/ngày',
              ),
              if (_notesController.text.trim().isNotEmpty)
                _ReviewRow('Ghi chú PT', _notesController.text.trim()),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Macros Breakdown Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tổng calo & Phân bổ Macros',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MacroStatCard(
                      label: 'Calo/ngày',
                      value: '$averageCalories kcal',
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFF7ED),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroStatCard(
                      label: 'Protein',
                      value: '$averageProtein g',
                      color: AppColors.primary,
                      bgColor: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroStatCard(
                      label: 'Carbs',
                      value: '$averageCarbs g',
                      color: AppColors.primary,
                      bgColor: AppColors.primary.withValues(alpha: 0.05),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroStatCard(
                      label: 'Fat',
                      value: '$averageFat g',
                      color: AppColors.primary,
                      bgColor: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ReviewRow('Tổng số món', '$totalItems món'),
              _ReviewRow('Tổng calo cả kỳ', '$totalCal kcal'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Meals List Review Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Thực đơn xem lại',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in const [
                ('breakfast', 'Bữa sáng'),
                ('lunch', 'Bữa trưa'),
                ('dinner', 'Bữa tối'),
                ('snack', 'Bữa phụ'),
              ])
                if (_itemsByMeal[entry.$1]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      entry.$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  for (final item in _itemsByMeal[entry.$1]!)
                    _ReviewMealItem(item: item),
                  const Divider(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadSuitableSuggestions() async {
    final target = _targetCalories;
    if (target == null || target <= 0) return const [];

    setState(() {
      _loadingSuggestions = true;
      _suggestionsError = null;
    });
    try {
      final suggestions = await context
          .read<CoachMealPlanProvider>()
          .loadSuggestions(
            date: _resolvedRange.$1,
            targetCalories: target,
            minCalories: _minCalories,
            maxCalories: _maxCalories,
            minProteinG: double.tryParse(_minProteinController.text.trim()),
            maxProteinG: double.tryParse(_maxProteinController.text.trim()),
            top: 20,
          );
      if (!mounted) return const [];
      setState(() => _suggestions = suggestions);
      return suggestions;
    } catch (error) {
      if (!mounted) return const [];
      setState(() {
        _suggestions = const [];
        _suggestionsError =
            'Không thể tải danh sách món phù hợp. Vui lòng thử lại.';
      });
      return const [];
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _initializeFromSuggestions() async {
    var suggestions = _suggestions;
    if (suggestions.isEmpty) {
      suggestions = await _loadSuitableSuggestions();
    }
    if (!mounted || suggestions.isEmpty) {
      if (mounted && _suggestionsError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không có món nào nằm trong khoảng kcal đã cấu hình.',
            ),
          ),
        );
      }
      return;
    }

    const slots = ['breakfast', 'lunch', 'dinner', 'snack'];
    final generated = {for (final slot in slots) slot: <_DraftItemDraft>[]};
    var suggestionIndex = 0;
    for (final date in _planDates) {
      for (final slot in slots) {
        final suggestion = suggestions[suggestionIndex % suggestions.length];
        suggestionIndex++;
        generated[slot]!.add(
          _draftFromSuggestion(suggestion, mealType: slot, plannedDate: date),
        );
      }
    }

    setState(() {
      for (final slot in slots) {
        _itemsByMeal[slot]!
          ..clear()
          ..addAll(generated[slot]!);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã khởi tạo lộ trình. PT có thể thêm, thay thế hoặc xóa món trước khi lưu.',
        ),
      ),
    );
  }

  _DraftItemDraft _draftFromSuggestion(
    Map<String, dynamic> suggestion, {
    required String mealType,
    required DateTime plannedDate,
  }) {
    final type = _mapString(suggestion, 'type').toLowerCase();
    final id = _mapString(suggestion, 'id');
    final name = _mapString(suggestion, 'name');
    return _DraftItemDraft(
      mealType: mealType,
      foodId: type == 'recipe' ? null : id,
      recipeId: type == 'recipe' ? id : null,
      label: name,
      plannedDate: plannedDate,
      scheduledTime: _mealDefaultTime(mealType),
      targetCalories: _mapInt(suggestion, 'caloriesKcal'),
      proteinG: _mapDouble(suggestion, 'proteinG'),
      carbsG: _mapDouble(suggestion, 'carbsG'),
      fatG: _mapDouble(suggestion, 'fatG'),
    );
  }

  Future<void> _pickItemFor(
    String mealType, {
    _DraftItemDraft? replacing,
  }) async {
    final pick = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _IngredientPickerSheet(),
    );
    if (pick != null && mounted) {
      final plannedDate = replacing?.plannedDate ?? _resolvedRange.$1;
      final replacement = _DraftItemDraft(
        mealType: mealType,
        foodId: pick.kind == _IngredientKind.food ? pick.id : null,
        recipeId: pick.kind == _IngredientKind.recipe ? pick.id : null,
        label: pick.name,
        plannedDate: plannedDate,
        scheduledTime: replacing?.scheduledTime ?? _mealDefaultTime(mealType),
        targetCalories: pick.calories,
        proteinG: pick.proteinG,
        carbsG: pick.carbsG,
        fatG: pick.fatG,
      );
      setState(() {
        final items = _itemsByMeal[mealType]!;
        final replaceIndex = replacing == null ? -1 : items.indexOf(replacing);
        if (replaceIndex >= 0) {
          items[replaceIndex] = replacement;
        } else {
          items.add(replacement);
        }
      });
    }
  }

  Future<void> _editDraftItem(_DraftItemDraft item) async {
    final caloriesController = TextEditingController(
      text: item.targetCalories?.toString() ?? '',
    );
    final proteinController = TextEditingController(
      text: item.proteinG?.toStringAsFixed(0) ?? '',
    );
    final carbsController = TextEditingController(
      text: item.carbsG?.toStringAsFixed(0) ?? '',
    );
    final fatController = TextEditingController(
      text: item.fatG?.toStringAsFixed(0) ?? '',
    );
    final timeController = TextEditingController(
      text: item.scheduledTime ?? _mealDefaultTime(item.mealType),
    );
    var selectedDate = item.plannedDate ?? _resolvedRange.$1;

    final edited = await showDialog<_DraftItemDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chỉnh sửa ${item.label}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<DateTime>(
                  initialValue: selectedDate,
                  decoration: const InputDecoration(
                    labelText: 'Ngày dùng món',
                    border: OutlineInputBorder(),
                  ),
                  items: _planDates
                      .map(
                        (date) => DropdownMenuItem(
                          value: date,
                          child: Text(_fmt(date)),
                        ),
                      )
                      .toList(),
                  onChanged: (date) {
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Giờ ăn (HH:mm)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calo (kcal)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Protein'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Carbs'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Fat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _DraftItemDraft(
                  mealType: item.mealType,
                  foodId: item.foodId,
                  recipeId: item.recipeId,
                  label: item.label,
                  plannedDate: selectedDate,
                  scheduledTime: timeController.text.trim(),
                  targetCalories: int.tryParse(caloriesController.text.trim()),
                  proteinG: double.tryParse(proteinController.text.trim()),
                  carbsG: double.tryParse(carbsController.text.trim()),
                  fatG: double.tryParse(fatController.text.trim()),
                ),
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    timeController.dispose();
    if (edited == null || !mounted) return;

    setState(() {
      final items = _itemsByMeal[item.mealType]!;
      final index = items.indexOf(item);
      if (index >= 0) items[index] = edited;
    });
  }

  static String _mealDefaultTime(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '07:30';
      case 'lunch':
        return '12:00';
      case 'dinner':
        return '18:30';
      default:
        return '15:00';
    }
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _mapString(Map<String, dynamic> map, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    return (map[key] ?? map[pascal] ?? '').toString();
  }

  static int? _mapInt(Map<String, dynamic> map, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    final value = map[key] ?? map[pascal];
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _mapDouble(Map<String, dynamic> map, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    final value = map[key] ?? map[pascal];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void _openItemDetail(_DraftItemDraft item) {
    final Widget? screen = item.foodId != null
        ? FoodDetailScreen(foodId: item.foodId!)
        : item.recipeId != null
        ? RecipeDetailScreen(recipeId: item.recipeId!)
        : null;
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  static String _scopeLabel(String scope) {
    return switch (scope.toLowerCase()) {
      'day' => 'Ngày',
      'week' => 'Tuần',
      'month' => 'Tháng',
      _ => 'Profile',
    };
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader({
    required this.currentStep,
    required this.onStepTapped,
  });

  final int currentStep;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    const steps = [(0, 'Cấu hình'), (1, 'Chọn món'), (2, 'Xem lại')];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: i <= currentStep ? () => onStepTapped(i) : null,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < currentStep
                            ? const Color(0xFF047857)
                            : (i == currentStep
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB)),
                        boxShadow: i == currentStep
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: i < currentStep
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: i == currentStep
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        steps[i].$2,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: i == currentStep
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: i == currentStep
                              ? AppColors.primary
                              : (i < currentStep
                                    ? const Color(0xFF047857)
                                    : Colors.grey.shade600),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 16,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: i < currentStep
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
          ],
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroStatCard extends StatelessWidget {
  const _MacroStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionPreview extends StatefulWidget {
  const _SuggestionPreview({required this.suggestions, required this.onView});

  final List<Map<String, dynamic>> suggestions;
  final void Function(Map<String, dynamic>) onView;

  @override
  State<_SuggestionPreview> createState() => _SuggestionPreviewState();
}

class _SuggestionPreviewState extends State<_SuggestionPreview> {
  static const _pageSize = 6;
  int _page = 0;

  @override
  void didUpdateWidget(covariant _SuggestionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestions != widget.suggestions) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = (widget.suggestions.length / _pageSize).ceil().clamp(
      1,
      999,
    );
    final safePage = _page.clamp(0, pageCount - 1);
    final visibleSuggestions = widget.suggestions
        .skip(safePage * _pageSize)
        .take(_pageSize)
        .toList();

    String value(Map<String, dynamic> item, String key) {
      final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
      return (item[key] ?? item[pascal] ?? '').toString();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Danh sách món ăn gợi ý',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
              ),
              Text(
                '${widget.suggestions.length} món',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < visibleSuggestions.length; index++) ...[
            Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.restaurant_rounded, size: 18),
                ),
                title: Text(
                  value(visibleSuggestions[index], 'name'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${value(visibleSuggestions[index], 'caloriesKcal')} kcal'
                  ' · P ${value(visibleSuggestions[index], 'proteinG')}g'
                  ' · C ${value(visibleSuggestions[index], 'carbsG')}g'
                  ' · F ${value(visibleSuggestions[index], 'fatG')}g',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => widget.onView(visibleSuggestions[index]),
              ),
            ),
            if (index < visibleSuggestions.length - 1)
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ],
          if (pageCount > 1) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: safePage == 0
                      ? null
                      : () => setState(() => _page = safePage - 1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Trang ${safePage + 1}/$pageCount',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Trang sau',
                  onPressed: safePage >= pageCount - 1
                      ? null
                      : () => setState(() => _page = safePage + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewMealItem extends StatelessWidget {
  const _ReviewMealItem({required this.item});

  final _DraftItemDraft item;

  @override
  Widget build(BuildContext context) {
    final date = item.plannedDate;
    final dateLabel = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (dateLabel.isNotEmpty) dateLabel,
                    if ((item.scheduledTime ?? '').isNotEmpty)
                      item.scheduledTime!,
                    '${item.targetCalories ?? 0} kcal',
                    'P ${(item.proteinG ?? 0).round()}g',
                    'C ${(item.carbsG ?? 0).round()}g',
                    'F ${(item.fatG ?? 0).round()}g',
                  ].join(' · '),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealPickerRow extends StatelessWidget {
  const _MealPickerRow({
    required this.mealType,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
    required this.onReplace,
    required this.onView,
  });

  final String mealType;
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final List<_DraftItemDraft> items;
  final VoidCallback onAdd;
  final void Function(_DraftItemDraft) onRemove;
  final void Function(_DraftItemDraft) onEdit;
  final void Function(_DraftItemDraft) onReplace;
  final void Function(_DraftItemDraft) onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length} món',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, size: 22),
                  color: textColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onAdd,
                  tooltip: 'Thêm món',
                ),
              ],
            ),
          ),

          // Items List
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chưa có món nào. Bấm nút + để chọn món cho $label.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      onTap: () => onView(items[i]),
                      title: Text(
                        items[i].label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                      subtitle: Text(
                        '${items[i].plannedDate == null ? '' : '${items[i].plannedDate!.day.toString().padLeft(2, '0')}/${items[i].plannedDate!.month.toString().padLeft(2, '0')}/${items[i].plannedDate!.year} · '}'
                        '${items[i].scheduledTime ?? ''}'
                        '${items[i].scheduledTime == null ? '' : ' · '}'
                        '${items[i].targetCalories ?? 0} kcal'
                        '${items[i].proteinG != null ? ' · P ${items[i].proteinG!.round()}g' : ''}'
                        '${items[i].carbsG != null ? ' · C ${items[i].carbsG!.round()}g' : ''}'
                        '${items[i].fatG != null ? ' · F ${items[i].fatG!.round()}g' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 19),
                            tooltip: 'Chỉnh sửa món',
                            onPressed: () => onEdit(items[i]),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              size: 20,
                            ),
                            tooltip: 'Thay món',
                            onPressed: () => onReplace(items[i]),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            tooltip: 'Xóa món',
                            onPressed: () => onRemove(items[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _DraftItemDraft {
  _DraftItemDraft({
    required this.mealType,
    this.foodId,
    this.recipeId,
    required this.label,
    this.plannedDate,
    this.scheduledTime,
    this.targetCalories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final String mealType;
  final String? foodId;
  final String? recipeId;
  final String label;
  final DateTime? plannedDate;
  final String? scheduledTime;
  final int? targetCalories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
}

class _PickResult {
  _PickResult({
    required this.id,
    required this.name,
    required this.kind,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });
  final String id;
  final String name;
  final _IngredientKind kind;
  final int? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
}

enum _IngredientKind { food, recipe }

class _IngredientPickerSheet extends StatefulWidget {
  const _IngredientPickerSheet();
  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final _repo = FoodDiscoveryRepository();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _repo.searchFoods(keyword: q),
        _repo.searchRecipes(keyword: q),
      ]);
      _results = [
        ...(results[0] as List).map(
          (item) => {
            'id': (item as dynamic).id,
            'name': item.nameVi,
            'type': 'food',
            'category': item.category,
            'caloriesKcal': item.caloriesKcal,
            'proteinG': item.proteinG,
            'carbsG': item.carbsG,
            'fatG': item.fatG,
          },
        ),
        ...(results[1] as List).map(
          (item) => {
            'id': (item as dynamic).id,
            'name': item.title,
            'type': 'recipe',
            'category': 'Công thức',
            'caloriesKcal': item.totalCalories,
          },
        ),
      ].take(20).toList();
    } catch (_) {
      _results = const [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn món', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên món...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: _search,
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(),
              if (!_loading && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Gõ và nhấn Enter để tìm kiếm.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              if (_results.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final it = _results[index];
                      final name = (it['name'] ?? it['Name'] ?? 'Món')
                          .toString();
                      final id = (it['id'] ?? it['Id'] ?? '').toString();
                      final calories = int.tryParse(
                        (it['caloriesKcal'] ??
                                it['CaloriesKcal'] ??
                                it['calories'] ??
                                '')
                            .toString(),
                      );
                      final kind = (it['type'] ?? '').toString() == 'recipe'
                          ? _IngredientKind.recipe
                          : _IngredientKind.food;
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                          '${(it['category'] ?? it['Category'] ?? '').toString()}'
                          '${calories == null ? '' : ' · $calories kcal'}',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _PickResult(
                            id: id,
                            name: name,
                            kind: kind,
                            calories: calories,
                            proteinG: _mapNullableDouble(it['proteinG']),
                            carbsG: _mapNullableDouble(it['carbsG']),
                            fatG: _mapNullableDouble(it['fatG']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static double? _mapNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
