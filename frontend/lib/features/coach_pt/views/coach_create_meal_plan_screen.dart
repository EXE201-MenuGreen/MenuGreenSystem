import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../discover/repositories/food_discovery_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../coach_pt.dart';

/// Coach-side create-meal-plan screen.
///
/// PT configures calories, generates suitable meal suggestions for a
/// day/week/month, then sends the concrete plan for Gymer acceptance.
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
  final _formKey = GlobalKey<FormState>();
  String _planType = 'weekly';
  DateTime? _singleDate = DateTime.now();
  int? _targetCalories;
  int? _minCalories;
  int? _maxCalories;
  final _targetCaloriesController = TextEditingController();
  final _minCaloriesController = TextEditingController();
  final _maxCaloriesController = TextEditingController();
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
    _notesController.dispose();
    super.dispose();
  }

  /// Loại plan 'daily' chỉ chọn 1 ngày (StartDate == EndDate) thay vì range 1 tuần.
  /// Các loại khác (weekly/custom) vẫn dùng DateTimeRange.
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
      setState(() {
        _targetCalories = target;
        _minCalories = min;
        _maxCalories = max;
        _configSource = _mapString(config, 'scope');
        _targetCaloriesController.text = target?.toString() ?? '';
        _minCaloriesController.text = min?.toString() ?? '';
        _maxCaloriesController.text = max?.toString() ?? '';
      });
    } catch (_) {
      // PT can still enter an explicit configuration when the Gymer has none.
    }
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
          content: Text(
            'Đã lưu cấu hình và danh sách món. Bạn có thể mở bản nháp để chỉnh sửa, thay món hoặc gửi Gymer.',
          ),
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
      appBar: AppBar(title: Text('Tạo lộ trình - ${widget.clientName}')),
      body: Stepper(
        currentStep: _step,
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        onStepContinue: () async {
          if (_step == 0) {
            if (!(_formKey.currentState?.validate() ?? false) || !_canNext) {
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
        controlsBuilder: (ctx, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: !_canNext || _submitting
                      ? null
                      : details.onStepContinue,
                  child: Text(
                    _step == 2 ? 'Lưu bản nháp lộ trình' : 'Tiếp tục',
                  ),
                ),
                const SizedBox(width: 8),
                if (_step > 0)
                  TextButton(
                    onPressed: _submitting ? null : details.onStepCancel,
                    child: const Text('Quay lại'),
                  ),
                if (_submitting) ...[
                  const SizedBox(width: 16),
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Cấu hình'),
            isActive: _step >= 0,
            content: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _planType,
                    decoration: const InputDecoration(
                      labelText: 'Loại lộ trình',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text('Hàng ngày'),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Hàng tuần'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Hàng tháng'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _planType = v ?? 'weekly';
                    }),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _singleDate == null
                          ? (_isMonthly
                                ? 'Chọn tháng'
                                : _isDaily
                                ? 'Chọn ngày'
                                : 'Chọn tuần')
                          : (_isMonthly
                                ? 'Tháng: ${_singleDate!.month.toString().padLeft(2, '0')}/${_singleDate!.year}'
                                : _isDaily
                                ? 'Ngày: ${_fmt(_singleDate!)}'
                                : 'Tuần: ${_fmt(_resolvedRange.$1)} - ${_fmt(_resolvedRange.$2)}'),
                    ),
                    onPressed: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _configSource == 'profile'
                        ? 'Gymer chưa có cấu hình riêng cho ngày này; PT hãy nhập cấu hình mới.'
                        : 'Đang tham chiếu cấu hình ${_scopeLabel(_configSource)} của Gymer. PT có thể thay đổi trước khi gửi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _configSource == 'profile'
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _targetCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu calo / ngày',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _targetCalories = int.tryParse(v)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minCaloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Kcal món tối thiểu',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(
                            () => _minCalories = int.tryParse(value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _maxCaloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Kcal món tối đa',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => setState(
                            () => _maxCalories = int.tryParse(value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_minCalories != null &&
                      _maxCalories != null &&
                      _minCalories! > _maxCalories!) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Kcal tối thiểu không được lớn hơn kcal tối đa.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú của PT cho Gymer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Chọn món'),
            isActive: _step >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Danh sách món phù hợp với cấu hình',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: _loadingSuggestions
                                ? null
                                : _loadSuitableSuggestions,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Tải lại gợi ý',
                          ),
                        ],
                      ),
                      Text(
                        'Mục tiêu $_targetCalories kcal/ngày'
                        '${_minCalories == null ? '' : ' • từ $_minCalories kcal/món'}'
                        '${_maxCalories == null ? '' : ' • tối đa $_maxCalories kcal/món'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_loadingSuggestions) ...[
                        const SizedBox(height: 10),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 6),
                        const Text('Đang tìm món phù hợp cho Gymer...'),
                      ] else if (_suggestionsError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _suggestionsError!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          _suggestions.isEmpty
                              ? 'Không tìm thấy món phù hợp. Hãy điều chỉnh khoảng kcal hoặc tải lại.'
                              : 'Đã tìm thấy ${_suggestions.length} món. PT có thể xem, thêm từng món hoặc khởi tạo tự động.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (!_loadingSuggestions && _suggestions.isNotEmpty) ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      final name = _mapString(suggestion, 'name');
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              _mapString(suggestion, 'type').toLowerCase() ==
                                      'recipe'
                                  ? Icons.menu_book_outlined
                                  : Icons.restaurant_outlined,
                            ),
                          ),
                          title: Text(name.isEmpty ? 'Món ăn' : name),
                          subtitle: Text(_suggestionNutritionLabel(suggestion)),
                          onTap: () => _openSuggestionDetail(suggestion),
                          trailing: IconButton.filledTonal(
                            onPressed: () => _addSuggestionToMeal(suggestion),
                            icon: const Icon(Icons.add),
                            tooltip: 'Thêm món vào lộ trình',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _initializeFromSuggestions,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        _itemsByMeal.values.any((items) => items.isNotEmpty)
                            ? 'Khởi tạo lại lộ trình từ gợi ý'
                            : 'Khởi tạo lộ trình từ gợi ý',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                for (final mealType in const [
                  ('breakfast', 'Bữa sáng'),
                  ('lunch', 'Bữa trưa'),
                  ('dinner', 'Bữa tối'),
                  ('snack', 'Bữa phụ'),
                ])
                  _MealPickerRow(
                    mealType: mealType.$1,
                    label: mealType.$2,
                    items: _itemsByMeal[mealType.$1]!,
                    onAdd: () => _pickItemFor(mealType.$1),
                    onRemove: (it) =>
                        setState(() => _itemsByMeal[mealType.$1]!.remove(it)),
                    onReplace: (it) => _pickItemFor(mealType.$1, replacing: it),
                    onView: _openItemDetail,
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Xem lại'),
            isActive: _step >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loại: $_planType'),
                if (_singleDate != null)
                  Text(
                    'Khoảng: ${_fmt(_resolvedRange.$1)} - '
                    '${_fmt(_resolvedRange.$2)}',
                  ),
                Text('Mục tiêu: $_targetCalories kcal/ngày'),
                if (_minCalories != null || _maxCalories != null)
                  Text(
                    'Khoảng món: ${_minCalories ?? 0} - '
                    '${_maxCalories ?? 'không giới hạn'} kcal',
                  ),
                if (_notesController.text.trim().isNotEmpty)
                  Text('Ghi chú PT: ${_notesController.text.trim()}'),
                const SizedBox(height: 12),
                for (final entry in _itemsByMeal.entries)
                  if (entry.value.isNotEmpty) ...[
                    Text(
                      entry.key.toUpperCase(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final it in entry.value)
                      Text(
                        '  • ${it.label}'
                        '${it.targetCalories == null ? '' : ' (${it.targetCalories} kcal)'}',
                      ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
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
          _draftFromSuggestion(
            suggestion,
            mealType: slot,
            plannedDate: date,
            includeDateInLabel: true,
          ),
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
    bool includeDateInLabel = false,
  }) {
    final type = _mapString(suggestion, 'type').toLowerCase();
    final id = _mapString(suggestion, 'id');
    final name = _mapString(suggestion, 'name');
    return _DraftItemDraft(
      mealType: mealType,
      foodId: type == 'recipe' ? null : id,
      recipeId: type == 'recipe' ? id : null,
      label: includeDateInLabel ? '$name • ${_fmt(plannedDate)}' : name,
      plannedDate: plannedDate,
      scheduledTime: _mealDefaultTime(mealType),
      targetCalories: _mapInt(suggestion, 'caloriesKcal'),
      proteinG: _mapDouble(suggestion, 'proteinG'),
      carbsG: _mapDouble(suggestion, 'carbsG'),
      fatG: _mapDouble(suggestion, 'fatG'),
    );
  }

  Future<void> _addSuggestionToMeal(Map<String, dynamic> suggestion) async {
    final mealType = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ListTile(
              title: Text(
                'Thêm món vào bữa nào?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            _MealTypeChoice(value: 'breakfast', label: 'Bữa sáng'),
            _MealTypeChoice(value: 'lunch', label: 'Bữa trưa'),
            _MealTypeChoice(value: 'dinner', label: 'Bữa tối'),
            _MealTypeChoice(value: 'snack', label: 'Bữa phụ'),
          ],
        ),
      ),
    );
    if (!mounted || mealType == null) return;

    var plannedDate = _resolvedRange.$1;
    if (_planDates.length > 1) {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: plannedDate,
        firstDate: _resolvedRange.$1,
        lastDate: _resolvedRange.$2,
      );
      if (!mounted || pickedDate == null) return;
      plannedDate = pickedDate;
    }

    setState(() {
      _itemsByMeal[mealType]!.add(
        _draftFromSuggestion(
          suggestion,
          mealType: mealType,
          plannedDate: plannedDate,
          includeDateInLabel: _planDates.length > 1,
        ),
      );
    });
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

  static String _suggestionNutritionLabel(Map<String, dynamic> suggestion) {
    final calories = _mapInt(suggestion, 'caloriesKcal') ?? 0;
    final protein = _mapDouble(suggestion, 'proteinG');
    final carbs = _mapDouble(suggestion, 'carbsG');
    final fat = _mapDouble(suggestion, 'fatG');
    return <String>[
      '$calories kcal',
      if (protein != null) 'P ${protein.round()}g',
      if (carbs != null) 'C ${carbs.round()}g',
      if (fat != null) 'F ${fat.round()}g',
      'Chạm để xem chi tiết',
    ].join(' • ');
  }

  void _openSuggestionDetail(Map<String, dynamic> suggestion) {
    final id = _mapString(suggestion, 'id');
    final isRecipe = _mapString(suggestion, 'type').toLowerCase() == 'recipe';
    if (id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isRecipe
            ? RecipeDetailScreen(recipeId: id)
            : FoodDetailScreen(foodId: id),
      ),
    );
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

class _MealTypeChoice extends StatelessWidget {
  const _MealTypeChoice({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.restaurant_menu),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

class _MealPickerRow extends StatelessWidget {
  const _MealPickerRow({
    required this.mealType,
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onReplace,
    required this.onView,
  });

  final String mealType;
  final String label;
  final List<_DraftItemDraft> items;
  final VoidCallback onAdd;
  final void Function(_DraftItemDraft) onRemove;
  final void Function(_DraftItemDraft) onReplace;
  final void Function(_DraftItemDraft) onView;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: onAdd,
                  tooltip: 'Thêm món',
                ),
              ],
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Text(
                  'Chưa có món',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: items
                    .map(
                      (it) => ListTile(
                        title: Text(it.label),
                        subtitle: Text(_nutritionLabel(it)),
                        onTap: () => onView(it),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              tooltip: 'Thay món',
                              onPressed: () => onReplace(it),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: 'Xóa món',
                              onPressed: () => onRemove(it),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  static String _nutritionLabel(_DraftItemDraft item) {
    final parts = <String>[
      '${item.targetCalories ?? 0} kcal',
      if (item.proteinG != null) 'P ${item.proteinG!.round()}g',
      if (item.carbsG != null) 'C ${item.carbsG!.round()}g',
      if (item.fatG != null) 'F ${item.fatG!.round()}g',
    ];
    return '${parts.join(' · ')}  •  Chạm để xem chi tiết';
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
