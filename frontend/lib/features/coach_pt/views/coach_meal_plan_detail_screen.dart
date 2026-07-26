import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../advanced/repositories/advanced_repository.dart';
import '../coach_pt.dart';

/// Coach edits a specific Gymer's meal plan.
///
/// * Tapping a meal item opens an inline edit sheet (Delete / Replace).
/// * Adding a new item pushes a bottom sheet that picks a food/recipe from the
///   ingredient catalog (using the existing `/Ingredient/search` endpoint).
/// * The bottom action bar offers "Lưu nháp" and "Duyệt & gửi" (which calls
///   `submitClientMealPlan` server-side and notifies the Gymer).
class CoachMealPlanDetailScreen extends StatefulWidget {
  const CoachMealPlanDetailScreen({super.key, required this.planId});
  final String planId;

  @override
  State<CoachMealPlanDetailScreen> createState() =>
      _CoachMealPlanDetailScreenState();
}

class _CoachMealPlanDetailScreenState extends State<CoachMealPlanDetailScreen> {
  bool _dirty = false;
  String? _initializedPlanId;
  late final List<_DraftItem> _draft;

  @override
  void initState() {
    super.initState();
    _draft = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachMealPlanProvider>().loadPlanDetail(widget.planId);
    });
  }

  CoachMealPlanDetail? get _plan =>
      context.read<CoachMealPlanProvider>().selectedPlan;

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _saveDraft() async {
    final payload = ClientMealPlanPayload(
      title: _plan!.header.title,
      planType: _plan!.header.planType,
      startDate: _plan!.header.startDate,
      endDate: _plan!.header.endDate,
      targetCalories: _plan!.header.targetCalories,
      items: _draft.map((d) => d.toPayload()).toList(),
    );
    final ok = await context
        .read<CoachMealPlanProvider>()
        .updatePlan(widget.planId, payload);
    if (!mounted) return;
    if (ok) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu nháp lộ trình.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thất bại. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _submit() async {
    if (_dirty) await _saveDraft();
    if (!mounted) return;
    final controller = TextEditingController();
    final notes = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt & gửi cho học viên'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Ghi chú cho học viên (tuỳ chọn)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !mounted) return;
    final ok = await context
        .read<CoachMealPlanProvider>()
        .submitPlan(widget.planId, notes: notes.isEmpty ? null : notes);
    if (!mounted) return;
    if (ok) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt và gửi lộ trình. Học viên sẽ nhận thông báo.'),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi thất bại. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoachMealPlanProvider>();
    final plan = provider.selectedPlan;

    if (provider.isLoadingDetail || plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lộ trình')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.detailError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lộ trình')),
        body: _ErrorState(message: provider.detailError!),
      );
    }

    if (_initializedPlanId != plan.header.id && !_dirty) {
      _initializedPlanId = plan.header.id;
      _draft.clear();
      final itemsByMeal = plan.itemsByMeal;
      for (final entry in itemsByMeal.entries) {
        _draft.addAll(entry.value.map(_DraftItem.fromItem));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.header.title.isNotEmpty
            ? plan.header.title
            : 'Lộ trình'),
        actions: [
          if (_dirty)
            IconButton(
              tooltip: 'Lưu nháp',
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveDraft,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_dirty)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu nháp'),
                    onPressed: _saveDraft,
                  ),
                ),
              if (_dirty) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Duyệt & gửi'),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(plan: plan),
          const SizedBox(height: 16),
          ..._buildMealSections(context, plan),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMealItem',
        onPressed: () => _showAddItemSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildMealSections(BuildContext context, CoachMealPlanDetail plan) {
    const mealOrder = [
      ('breakfast', 'Bữa sáng'),
      ('lunch', 'Bữa trưa'),
      ('dinner', 'Bữa tối'),
      ('snack', 'Bữa phụ'),
    ];
    final sections = <Widget>[];
    for (final entry in mealOrder) {
      final items = _draft.where((d) => d.mealType == entry.$1).toList();
      sections.add(_MealSection(
        title: entry.$2,
        items: items,
        onEdit: _editItem,
        onDelete: (it) {
          setState(() => _draft.remove(it));
          _markDirty();
        },
      ));
      sections.add(const SizedBox(height: 16));
    }
    return sections;
  }

  Future<void> _editItem(_DraftItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Thay món khác'),
              onTap: () => Navigator.pop(ctx, 'replace'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa khỏi lộ trình',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'delete') {
      setState(() => _draft.remove(item));
      _markDirty();
    } else if (action == 'replace') {
      final pick = await _showIngredientPicker(context);
      if (pick != null && mounted) {
        setState(() {
          item.foodId = pick.kind == _IngredientKind.food ? pick.id : null;
          item.recipeId = pick.kind == _IngredientKind.recipe ? pick.id : null;
          item.displayName = pick.name;
        });
        _markDirty();
      }
    }
  }

  Future<_IngredientPick?> _showIngredientPicker(BuildContext context) {
    return showModalBottomSheet<_IngredientPick>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _IngredientPickerSheet(),
    );
  }

  Future<void> _showAddItemSheet(BuildContext context) async {
    String mealType = 'breakfast';
    final result = await showModalBottomSheet<_AddItemResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thêm món mới',
                    style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mealType,
                  decoration: const InputDecoration(
                    labelText: 'Bữa',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'breakfast', child: Text('Bữa sáng')),
                    DropdownMenuItem(value: 'lunch', child: Text('Bữa trưa')),
                    DropdownMenuItem(value: 'dinner', child: Text('Bữa tối')),
                    DropdownMenuItem(value: 'snack', child: Text('Bữa phụ')),
                  ],
                  onChanged: (v) => setSheet(() => mealType = v ?? 'breakfast'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Chọn món / công thức'),
                  onPressed: () async {
                    final pick = await _showIngredientPicker(context);
                    if (pick != null && ctx.mounted) {
                      Navigator.pop(
                        ctx,
                        _AddItemResult(mealType: mealType, pick: pick),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _draft.add(_DraftItem(
          id: null,
          mealType: result.mealType,
          foodId:
              result.pick.kind == _IngredientKind.food ? result.pick.id : null,
          recipeId: result.pick.kind == _IngredientKind.recipe
              ? result.pick.id
              : null,
          displayName: result.pick.name,
        ));
      });
      _markDirty();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plan});
  final CoachMealPlanDetail plan;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.header.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Text('${plan.header.targetCalories ?? '-'} kcal',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('Loại: ${plan.header.planType}',
                style: Theme.of(context).textTheme.bodySmall),
            if (plan.header.startDate != null && plan.header.endDate != null)
              Text(
                'Từ ${plan.header.startDate!.day}/${plan.header.startDate!.month}/${plan.header.startDate!.year}'
                ' đến ${plan.header.endDate!.day}/${plan.header.endDate!.month}/${plan.header.endDate!.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (plan.header.coachName != null &&
                plan.header.coachName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Chip(
                  avatar: const Icon(Icons.badge_outlined, size: 16),
                  label: Text('Tạo bởi PT ${plan.header.coachName}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<_DraftItem> items;
  final Future<void> Function(_DraftItem) onEdit;
  final void Function(_DraftItem) onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa có món. Bấm + để thêm.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              Column(
                children: items
                    .map((it) => _DraftItemTile(
                          item: it,
                          onTap: () => onEdit(it),
                          onDelete: () => onDelete(it),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _DraftItemTile extends StatelessWidget {
  const _DraftItemTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final _DraftItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.restaurant),
      ),
      title: Text(item.displayName),
      subtitle: Text(item.recipeId != null ? 'Công thức' : 'Món'),
      trailing: IconButton(
        tooltip: 'Xoá',
        icon: const Icon(Icons.close, color: Colors.red),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

class _DraftItem {
  _DraftItem({
    required this.id,
    required this.mealType,
    this.foodId,
    this.recipeId,
    required this.displayName,
  });

  factory _DraftItem.fromItem(CoachMealPlanItem it) => _DraftItem(
        id: it.id,
        mealType: it.mealType.toLowerCase(),
        foodId: it.foodId,
        recipeId: it.recipeId,
        displayName: it.displayName,
      );

  String? id;
  final String mealType;
  String? foodId;
  String? recipeId;
  String displayName;

  ClientMealPlanItemPayload toPayload() => ClientMealPlanItemPayload(
        id: id,
        mealType: mealType,
        foodId: foodId,
        recipeId: recipeId,
      );
}

class _IngredientPick {
  _IngredientPick({
    required this.id,
    required this.name,
    required this.kind,
  });
  final String id;
  final String name;
  final _IngredientKind kind;
}

enum _IngredientKind { food, recipe }

class _AddItemResult {
  _AddItemResult({required this.mealType, required this.pick});
  final String mealType;
  final _IngredientPick pick;
}

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
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }
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
              Text('Chọn món / công thức',
                  style: Theme.of(context).textTheme.titleMedium),
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
                      final id =
                          (it['id'] ?? it['Id'] ?? '').toString();
                      return ListTile(
                        title: Text(name),
                        subtitle: Text((it['category'] ?? it['Category'] ?? '')
                            .toString()),
                        onTap: () => Navigator.pop(
                          context,
                          _IngredientPick(
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}
