import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../advanced/repositories/advanced_repository.dart';
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
      return _singleDate != null && _targetCalories != null && validBounds;
    }
    if (_step == 1) {
      return _itemsByMeal.values.any((items) => items.isNotEmpty);
    }
    return true;
  }

  Future<void> _submit() async {
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
      items: items,
    );

    final ok = await context.read<CoachMealPlanProvider>().createAndSubmitPlan(
      payload,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      minCalories: _minCalories,
      maxCalories: _maxCalories,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã khởi tạo và gửi lộ trình. Đang chờ Gymer chấp nhận.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo lộ trình thất bại. Vui lòng thử lại.'),
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
        onStepContinue: () {
          if (_step < 2) {
            setState(() => _step++);
          } else {
            _submit();
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
                  child: Text(_step == 2 ? 'Khởi tạo & gửi Gymer' : 'Tiếp tục'),
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
                      const Text(
                        'Gợi ý theo cấu hình kcal của PT',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mục tiêu $_targetCalories kcal/ngày'
                        '${_minCalories == null ? '' : ' • từ $_minCalories kcal/món'}'
                        '${_maxCalories == null ? '' : ' • tối đa $_maxCalories kcal/món'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_suggestions.isNotEmpty)
                        Text(
                          'Đã tìm thấy ${_suggestions.length} món phù hợp.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _loadingSuggestions
                              ? null
                              : _initializeFromSuggestions,
                          icon: _loadingSuggestions
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _itemsByMeal.values.any((items) => items.isNotEmpty)
                                ? 'Tạo lại danh sách món'
                                : 'Khởi tạo danh sách món',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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

  Future<void> _initializeFromSuggestions() async {
    final target = _targetCalories;
    if (target == null || target <= 0) return;

    setState(() => _loadingSuggestions = true);
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
      if (!mounted) return;
      if (suggestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không có món nào nằm trong khoảng kcal đã cấu hình.',
            ),
          ),
        );
        return;
      }

      const slots = ['breakfast', 'lunch', 'dinner', 'snack'];
      final generated = {for (final slot in slots) slot: <_DraftItemDraft>[]};
      var suggestionIndex = 0;
      for (final date in _planDates) {
        for (final slot in slots) {
          final suggestion = suggestions[suggestionIndex % suggestions.length];
          suggestionIndex++;
          final type = _mapString(suggestion, 'type').toLowerCase();
          final id = _mapString(suggestion, 'id');
          final name = _mapString(suggestion, 'name');
          generated[slot]!.add(
            _DraftItemDraft(
              mealType: slot,
              foodId: type == 'recipe' ? null : id,
              recipeId: type == 'recipe' ? id : null,
              label: '$name • ${_fmt(date)}',
              plannedDate: date,
              scheduledTime: _mealDefaultTime(slot),
              targetCalories: _mapInt(suggestion, 'caloriesKcal'),
            ),
          );
        }
      }

      setState(() {
        _suggestions = suggestions;
        for (final slot in slots) {
          _itemsByMeal[slot]!
            ..clear()
            ..addAll(generated[slot]!);
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tạo gợi ý: $error')));
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _pickItemFor(String mealType) async {
    final pick = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _IngredientPickerSheet(),
    );
    if (pick != null && mounted) {
      final plannedDate = _resolvedRange.$1;
      setState(() {
        _itemsByMeal[mealType]!.add(
          _DraftItemDraft(
            mealType: mealType,
            foodId: pick.kind == _IngredientKind.food ? pick.id : null,
            recipeId: pick.kind == _IngredientKind.recipe ? pick.id : null,
            label: pick.name,
            plannedDate: plannedDate,
            scheduledTime: _mealDefaultTime(mealType),
            targetCalories: pick.calories,
          ),
        );
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

  static String _scopeLabel(String scope) {
    return switch (scope.toLowerCase()) {
      'day' => 'Ngày',
      'week' => 'Tuần',
      'month' => 'Tháng',
      _ => 'Profile',
    };
  }
}

class _MealPickerRow extends StatelessWidget {
  const _MealPickerRow({
    required this.mealType,
    required this.label,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String mealType;
  final String label;
  final List<_DraftItemDraft> items;
  final VoidCallback onAdd;
  final void Function(_DraftItemDraft) onRemove;

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
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => onRemove(it),
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
  });

  final String mealType;
  final String? foodId;
  final String? recipeId;
  final String label;
  final DateTime? plannedDate;
  final String? scheduledTime;
  final int? targetCalories;
}

class _PickResult {
  _PickResult({
    required this.id,
    required this.name,
    required this.kind,
    this.calories,
  });
  final String id;
  final String name;
  final _IngredientKind kind;
  final int? calories;
}

enum _IngredientKind { food, recipe }

class _IngredientPickerSheet extends StatefulWidget {
  const _IngredientPickerSheet();
  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final _repo = AdvancedRepository();
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
      final raw = await _repo.ingredients(q, false);
      _results = raw.take(20).toList();
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
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                          (it['category'] ?? it['Category'] ?? '').toString(),
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _PickResult(
                            id: id,
                            name: name,
                            kind: _IngredientKind.food,
                            calories: calories,
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
}
