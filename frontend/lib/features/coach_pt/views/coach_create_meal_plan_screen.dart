import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../advanced/repositories/advanced_repository.dart';
import '../coach_pt.dart';

/// Coach-side create-meal-plan screen.
///
/// MVP scope (Phase 4):
///   Step 1: choose planType + dates + targetCalories.
///   Step 2: pick meals per mealType (breakfast/lunch/dinner/snack) by
///           searching the Ingredient catalog.
///   Step 3: review and create.
///
/// Not implemented here (deliberately):
///   * Daily budget picker (use Gymer's target in future).
///   * Recipe vs Food picker screen (we ship the same as Gymer's "create").
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
  DateTime? _singleDate;
  DateTimeRange? _range;
  int? _targetCalories;
  final Map<String, List<_DraftItemDraft>> _itemsByMeal = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snack': [],
  };
  bool _submitting = false;

  /// Loại plan 'daily' chỉ chọn 1 ngày (StartDate == EndDate) thay vì range 1 tuần.
  /// Các loại khác (weekly/custom) vẫn dùng DateTimeRange.
  bool get _isDaily => _planType == 'daily';

  String _defaultTitle() {
    final now = DateTime.now();
    return 'Lộ trình của ${widget.clientName} - ${now.day}/${now.month}/${now.year}';
  }

  Future<void> _pickDate() async {
    final initial = _singleDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: initial,
    );
    if (picked != null) setState(() => _singleDate = picked);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  bool get _canNext {
    if (_step == 0) {
      // daily: cần _singleDate; weekly/custom: cần _range
      if (_isDaily) return _singleDate != null && _targetCalories != null;
      return _range != null && _targetCalories != null;
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
        .map((d) => ClientMealPlanItemPayload(
              mealType: d.mealType,
              foodId: d.foodId,
              recipeId: d.recipeId,
              plannedDate: d.plannedDate,
              scheduledTime: d.scheduledTime,
            ))
        .toList();

    final DateTime startDate;
    final DateTime endDate;
    if (_isDaily) {
      // daily: start == end (cùng 1 ngày) để UI Lộ trình hiển thị đúng "26/07"
      // thay vì "26/07 – 02/08" như trước đây (do showDateRangePicker mặc định 1 tuần).
      final d = _singleDate!;
      startDate = DateTime(d.year, d.month, d.day);
      endDate = startDate;
    } else {
      startDate = _range!.start;
      endDate = _range!.end;
    }

    final payload = ClientMealPlanPayload(
      title: _defaultTitle(),
      planType: _planType,
      startDate: startDate,
      endDate: endDate,
      targetCalories: _targetCalories,
      items: items,
    );

    final ok = await context.read<CoachMealPlanProvider>().createPlan(payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo lộ trình cho học viên.')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo lộ trình thất bại. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo lộ trình - ${widget.clientName}'),
      ),
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
                  onPressed: !_canNext || _submitting ? null : details.onStepContinue,
                  child: Text(_step == 2 ? 'Tạo lộ trình' : 'Tiếp tục'),
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
                      DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                      DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                      DropdownMenuItem(value: 'custom', child: Text('Tùy chỉnh')),
                    ],
                    onChanged: (v) => setState(() {
                      _planType = v ?? 'weekly';
                      // Khi chuyển từ daily ↔ range, reset picker để tránh
                      // dùng nhầm dữ liệu cũ (singleDate vs range).
                      if (_isDaily && _range != null) {
                        _range = null;
                      } else if (!_isDaily && _singleDate != null) {
                        _singleDate = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (_isDaily)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_singleDate == null
                          ? 'Chọn ngày'
                          : 'Ngày: ${_fmt(_singleDate!)}'),
                      onPressed: _pickDate,
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_range == null
                          ? 'Chọn khoảng ngày'
                          : '${_fmt(_range!.start)} - ${_fmt(_range!.end)}'),
                      onPressed: _pickRange,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu calo / ngày',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _targetCalories = int.tryParse(v)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
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
                    onRemove: (it) => setState(
                        () => _itemsByMeal[mealType.$1]!.remove(it)),
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
                if (_isDaily && _singleDate != null)
                  Text('Ngày: ${_fmt(_singleDate!)}'),
                if (!_isDaily && _range != null)
                  Text('Khoảng: ${_fmt(_range!.start)} - ${_fmt(_range!.end)}'),
                Text('Mục tiêu: $_targetCalories kcal/ngày'),
                const SizedBox(height: 12),
                for (final entry in _itemsByMeal.entries)
                  if (entry.value.isNotEmpty) ...[
                    Text(entry.key.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall),
                    for (final it in entry.value) Text('  • ${it.label}'),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickItemFor(String mealType) async {
    final pick = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _IngredientPickerSheet(),
    );
    if (pick != null && mounted) {
      final DateTime? plannedDate = _isDaily ? _singleDate : _range?.start;
      setState(() {
        _itemsByMeal[mealType]!.add(_DraftItemDraft(
          mealType: mealType,
          foodId: pick.kind == _IngredientKind.food ? pick.id : null,
          recipeId: pick.kind == _IngredientKind.recipe ? pick.id : null,
          label: pick.name,
          plannedDate: plannedDate,
          scheduledTime: _mealDefaultTime(mealType),
        ));
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
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
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
                child: Text('Chưa có món', style: TextStyle(color: Colors.grey)),
              )
            else
              Column(
                children: items
                    .map((it) => ListTile(
                          title: Text(it.label),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => onRemove(it),
                          ),
                        ))
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
  });

  final String mealType;
  final String? foodId;
  final String? recipeId;
  final String label;
  final DateTime? plannedDate;
  final String? scheduledTime;
}

class _PickResult {
  _PickResult({required this.id, required this.name, required this.kind});
  final String id;
  final String name;
  final _IngredientKind kind;
}

enum _IngredientKind { food, recipe }

class _IngredientPickerSheet extends StatefulWidget {
  const _IngredientPickerSheet();
  @override
  State<_IngredientPickerSheet> createState() =>
      _IngredientPickerSheetState();
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
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                    child: Text('Gõ và nhấn Enter để tìm kiếm.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              if (_results.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final it = _results[index];
                      final name =
                          (it['name'] ?? it['Name'] ?? 'Món').toString();
                      final id = (it['id'] ?? it['Id'] ?? '').toString();
                      return ListTile(
                        title: Text(name),
                        subtitle: Text(
                            (it['category'] ?? it['Category'] ?? '').toString()),
                        onTap: () => Navigator.pop(
                          context,
                          _PickResult(
                            id: id,
                            name: name,
                            kind: _IngredientKind.food,
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
