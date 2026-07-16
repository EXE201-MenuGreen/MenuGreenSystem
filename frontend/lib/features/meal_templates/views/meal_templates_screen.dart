import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../models/meal_template_models.dart';
import '../repositories/meal_template_repository.dart';

class MealTemplatesScreen extends StatefulWidget {
  const MealTemplatesScreen({super.key});

  @override
  State<MealTemplatesScreen> createState() => _MealTemplatesScreenState();
}

class _MealTemplatesScreenState extends State<MealTemplatesScreen> {
  final _repository = MealTemplateRepository();
  List<MealTemplate> _templates = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final templates = await _repository.getAll();
      if (mounted) {
        setState(() => _templates = templates.where((item) => item.isActive).toList());
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([MealTemplate? template]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MealTemplateEditorScreen(template: template)),
    );
    if (changed == true) await _load();
  }

  Future<void> _logTemplate(MealTemplate template) async {
    MealTemplate detail;
    try {
      detail = await _repository.getById(template.id);
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
      return;
    }

    var date = DateTime.now();
    final quantityControllers = {
      for (final item in detail.items)
        item.id: TextEditingController(text: item.quantityG.toStringAsFixed(0)),
    };

    if (!mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày ghi nhật ký'),
                  subtitle: Text(_dateLabel(date)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setModalState(() => date = picked);
                  },
                ),
                const Divider(),
                const Text(
                  'Điều chỉnh khối lượng',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._mealTypes.map((type) {
                  final items = detail.items.where((item) => _itemMealType(item, template) == type).toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return _LogMealTypeSection(
                    mealType: type,
                    items: items,
                    controllers: quantityControllers,
                  );
                }),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ghi thực đơn này'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) {
      _disposeControllers(quantityControllers.values);
      return;
    }

    final itemQuantities = <Map<String, dynamic>>[];
    for (final item in detail.items) {
      final quantity = double.tryParse(quantityControllers[item.id]!.text.trim());
      if (quantity == null || quantity <= 0) {
        _disposeControllers(quantityControllers.values);
        if (mounted) _showMessage('Khối lượng phải lớn hơn 0.', error: true);
        return;
      }
      itemQuantities.add({'mealTemplateItemId': item.id, 'quantityG': quantity});
    }
    _disposeControllers(quantityControllers.values);

    try {
      final now = DateTime.now();
      await _repository.log(
        template.id,
        mealType: template.mealType ?? 'Snack',
        loggedAt: DateTime(date.year, date.month, date.day, now.hour, now.minute),
        itemQuantities: itemQuantities,
      );
      if (mounted) _showMessage('Đã ghi thực đơn "${template.title}".');
      await _load();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
    }
  }

  Future<void> _handleAction(String action, MealTemplate template) async {
    try {
      if (action == 'edit') await _openEditor(template);
      if (action == 'duplicate') {
        await _repository.duplicate(template.id);
        await _load();
      }
      if (action == 'delete') {
        await _repository.delete(template.id);
        await _load();
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString(), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thực đơn đã lưu')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tạo thực đơn',
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _templates.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('Chưa có thực đơn nào được lưu.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templates.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return Card(
                        child: ListTile(
                          onTap: () => _openEditor(template),
                          leading: const Icon(Icons.bookmark_outline, color: AppColors.primary),
                          title: Text(template.title),
                          subtitle: Text('${_templateTypeLabel(template)} • Đã dùng ${template.usageCount} lần'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Ghi thực đơn',
                                onPressed: () => _logTemplate(template),
                                icon: const Icon(Icons.add_task_outlined),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) => _handleAction(action, template),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                                  PopupMenuItem(value: 'duplicate', child: Text('Nhân bản')),
                                  PopupMenuItem(value: 'delete', child: Text('Xóa')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class MealTemplateEditorScreen extends StatefulWidget {
  const MealTemplateEditorScreen({super.key, this.template});

  final MealTemplate? template;

  @override
  State<MealTemplateEditorScreen> createState() => _MealTemplateEditorScreenState();
}

class _MealTemplateEditorScreenState extends State<MealTemplateEditorScreen> {
  final _repository = MealTemplateRepository();
  final _catalog = NutritionTrackingRepository();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<MealTemplateDraftItem> _items = [];
  var _saving = false;
  var _loadingPreset = false;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    if (template != null) {
      _titleController.text = template.title;
      _descriptionController.text = template.description ?? '';
      _loadDetails(template.id);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails(String id) async {
    try {
      final template = await _repository.getById(id);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(template.items.map((item) {
            final label = item.name?.isNotEmpty == true
                ? item.name!
                : item.isRecipe
                    ? 'Công thức đã chọn'
                    : 'Món ăn đã chọn';
            return MealTemplateDraftItem(
              foodId: item.foodId,
              recipeId: item.recipeId,
              mealType: item.mealType ?? template.mealType ?? 'Snack',
              label: label,
              quantityG: item.quantityG,
              notes: item.notes,
            );
          }));
      });
    } catch (_) {}
  }

  Future<void> _choosePreset() async {
    final preset = await showModalBottomSheet<_MealTemplatePreset>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Chọn thực đơn có sẵn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._mealTemplatePresets.map(
              (preset) => Card(
                child: ListTile(
                  title: Text(preset.title),
                  subtitle: Text(preset.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, preset),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (preset == null) return;
    await _applyPreset(preset);
  }

  Future<void> _applyPreset(_MealTemplatePreset preset) async {
    setState(() => _loadingPreset = true);
    final nextItems = <MealTemplateDraftItem>[];
    var missingCount = 0;

    for (final presetItem in preset.items) {
      final resolved = await _resolvePresetItem(presetItem);
      if (resolved == null) {
        missingCount++;
      } else {
        nextItems.add(resolved);
      }
    }

    if (!mounted) return;
    setState(() {
      _titleController.text = preset.title;
      _descriptionController.text = preset.description;
      _items
        ..clear()
        ..addAll(nextItems);
      _loadingPreset = false;
    });

    if (missingCount > 0) {
      _showEditorMessage(
        'Có $missingCount món gợi ý chưa tìm thấy trong catalog. Bạn có thể thêm thủ công.',
      );
    }
  }

  Future<MealTemplateDraftItem?> _resolvePresetItem(_PresetTemplateItem item) async {
    try {
      final foods = await _catalog.getFoods(keyword: item.keyword);
      if (foods.isNotEmpty) {
        final food = foods.first;
        return MealTemplateDraftItem(
          foodId: food.id,
          mealType: item.mealType,
          label: food.name,
          quantityG: item.quantityG,
        );
      }

      final recipes = await _catalog.getRecipes(keyword: item.keyword);
      if (recipes.isNotEmpty) {
        final recipe = recipes.first;
        return MealTemplateDraftItem(
          recipeId: recipe.id,
          mealType: item.mealType,
          label: recipe.name,
          quantityG: item.quantityG,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _addItem(String mealType) async {
    final item = await showModalBottomSheet<MealTemplateDraftItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TemplateItemPicker(catalog: _catalog, initialMealType: mealType),
    );
    if (item != null && mounted) setState(() => _items.add(item));
  }

  Future<void> _editItem(int index) async {
    final original = _items[index];
    final quantityController = TextEditingController(text: original.quantityG.toStringAsFixed(0));
    final notesController = TextEditingController(text: original.notes ?? '');
    var mealType = original.mealType;

    final updated = await showModalBottomSheet<MealTemplateDraftItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  original.label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openSelectedItemDetail(original),
                    icon: const Icon(Icons.info_outline),
                    label: Text(
                      original.recipeId != null && original.recipeId!.isNotEmpty
                          ? 'Xem chi tiết công thức'
                          : 'Xem chi tiết món ăn',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mealType,
                  decoration: const InputDecoration(labelText: 'Nhóm bữa'),
                  items: _mealTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(_mealTypeLabel(type))))
                      .toList(),
                  onChanged: (value) => setModalState(() => mealType = value ?? original.mealType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Khối lượng (gram)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final quantity = double.tryParse(quantityController.text.trim());
                      if (quantity == null || quantity <= 0) return;
                      Navigator.pop(
                        context,
                        MealTemplateDraftItem(
                          foodId: original.foodId,
                          recipeId: original.recipeId,
                          mealType: mealType,
                          label: original.label,
                          quantityG: quantity,
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Cập nhật món'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    quantityController.dispose();
    notesController.dispose();
    if (updated != null && mounted) setState(() => _items[index] = updated);
  }

  void _openSelectedItemDetail(MealTemplateDraftItem item) {
    if (item.recipeId != null && item.recipeId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeId: item.recipeId!)),
      );
      return;
    }

    if (item.foodId != null && item.foodId!.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: item.foodId!)),
      );
      return;
    }

    _showEditorMessage('Không tìm thấy thông tin chi tiết của món đã chọn.', error: true);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _items.isEmpty) {
      _showEditorMessage('Nhập tên thực đơn và thêm ít nhất một món.', error: true);
      return;
    }

    setState(() => _saving = true);
    final sortedItems = [..._items]
      ..sort((a, b) {
        final mealOrder = _mealTypeOrder(a.mealType).compareTo(_mealTypeOrder(b.mealType));
        return mealOrder != 0 ? mealOrder : _items.indexOf(a).compareTo(_items.indexOf(b));
      });
    final body = {
      'title': title,
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'mealType': 'Daily',
      'isActive': true,
      'items': [for (var i = 0; i < sortedItems.length; i++) sortedItems[i].toJson(i + 1)],
    };

    try {
      if (widget.template == null) {
        await _repository.create(body);
      } else {
        await _repository.update(widget.template!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showEditorMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showEditorMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template == null ? 'Tạo thực đơn' : 'Chỉnh sửa thực đơn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _loadingPreset ? null : _choosePreset,
            icon: _loadingPreset
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(_loadingPreset ? 'Đang nạp...' : 'Chọn thực đơn có sẵn'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Tên thực đơn'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Mô tả (không bắt buộc)'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Món trong thực đơn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._mealTypes.map((type) => _MealTypeEditorSection(
                mealType: type,
                items: _items,
                onAdd: () => _addItem(type),
                onEdit: _editItem,
                onRemove: (index) => setState(() => _items.removeAt(index)),
              )),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Đang lưu...' : 'Lưu thực đơn'),
          ),
        ],
      ),
    );
  }
}

class _MealTypeEditorSection extends StatelessWidget {
  const _MealTypeEditorSection({
    required this.mealType,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String mealType;
  final List<MealTemplateDraftItem> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final entries = items.asMap().entries.where((entry) => entry.value.mealType == mealType).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _mealTypeLabel(mealType),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Thêm món',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Chưa có món.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value.label),
                  subtitle: Text('${entry.value.quantityG.toStringAsFixed(0)} g'),
                  onTap: () => onEdit(entry.key),
                  trailing: IconButton(
                    tooltip: 'Xóa món',
                    onPressed: () => onRemove(entry.key),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogMealTypeSection extends StatelessWidget {
  const _LogMealTypeSection({
    required this.mealType,
    required this.items,
    required this.controllers,
  });

  final String mealType;
  final List<MealTemplateItem> items;
  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_mealTypeLabel(mealType), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...items.asMap().entries.map(
                (entry) => TextField(
                  controller: controllers[entry.value.id],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: _itemLabel(entry.value, entry.key)),
                ),
              ),
        ],
      ),
    );
  }
}

class _TemplateItemPicker extends StatefulWidget {
  const _TemplateItemPicker({
    required this.catalog,
    required this.initialMealType,
  });

  final NutritionTrackingRepository catalog;
  final String initialMealType;

  @override
  State<_TemplateItemPicker> createState() => _TemplateItemPickerState();
}

class _TemplateItemPickerState extends State<_TemplateItemPicker> {
  final _keywordController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  var _source = 'food';
  late String _mealType;
  List<CatalogItem> _catalogItems = const [];
  String? _selectedId;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _mealType = widget.initialMealType;
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final keyword = _keywordController.text.trim();
      final items = _source == 'food'
          ? await widget.catalog.getFoods(keyword: keyword)
          : await widget.catalog.getRecipes(keyword: keyword);
      if (mounted) {
        setState(() {
          _catalogItems = items;
          _selectedId = null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _catalogItems = const [];
          _selectedId = null;
          _loading = false;
        });
      }
    }
  }

  CatalogItem? _selectedItem() {
    for (final item in _catalogItems) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  void _submit() {
    final quantity = double.tryParse(_quantityController.text.trim());
    final selected = _selectedItem();
    if (selected == null || quantity == null || quantity <= 0) return;
    Navigator.pop(
      context,
      MealTemplateDraftItem(
        foodId: _source == 'food' ? selected.id : null,
        recipeId: _source == 'recipe' ? selected.id : null,
        mealType: _mealType,
        label: selected.name,
        quantityG: quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem();
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0;
    final canSubmit = selected != null && quantity > 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: const InputDecoration(labelText: 'Nhóm bữa'),
              items: _mealTypes.map((type) => DropdownMenuItem(value: type, child: Text(_mealTypeLabel(type)))).toList(),
              onChanged: (value) => setState(() => _mealType = value ?? widget.initialMealType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _source,
              decoration: const InputDecoration(labelText: 'Loại mục'),
              items: const [
                DropdownMenuItem(value: 'food', child: Text('Món ăn')),
                DropdownMenuItem(value: 'recipe', child: Text('Công thức')),
              ],
              onChanged: (value) {
                setState(() {
                  _source = value ?? 'food';
                  _catalogItems = const [];
                  _selectedId = null;
                });
                _search();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keywordController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: _source == 'food' ? 'Tìm món ăn' : 'Tìm công thức',
                suffixIcon: IconButton(
                  tooltip: 'Tìm',
                  onPressed: _loading ? null : _search,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _loading ? null : _search(),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey('$_source-${_catalogItems.length}-$_selectedId'),
                value: _selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Món trong thực đơn'),
                items: _catalogItems
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedId = value),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Khối lượng (gram)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: const Text('Thêm vào thực đơn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTemplatePreset {
  const _MealTemplatePreset({
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<_PresetTemplateItem> items;
}

class _PresetTemplateItem {
  const _PresetTemplateItem(this.mealType, this.keyword, this.quantityG);

  final String mealType;
  final String keyword;
  final double quantityG;
}

const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

const _mealTemplatePresets = [
  _MealTemplatePreset(
    title: 'Thực đơn cân bằng',
    description: 'Khung một ngày đủ 3 bữa chính và bữa phụ nhẹ.',
    items: [
      _PresetTemplateItem('Breakfast', 'yến mạch', 120),
      _PresetTemplateItem('Breakfast', 'sữa chua', 100),
      _PresetTemplateItem('Lunch', 'cơm gạo lứt', 150),
      _PresetTemplateItem('Lunch', 'ức gà', 120),
      _PresetTemplateItem('Dinner', 'cá', 120),
      _PresetTemplateItem('Dinner', 'salad', 150),
      _PresetTemplateItem('Snack', 'trái cây', 100),
    ],
  ),
  _MealTemplatePreset(
    title: 'Thực đơn giảm cân',
    description: 'Ưu tiên đạm nạc, rau và khẩu phần tinh bột vừa phải.',
    items: [
      _PresetTemplateItem('Breakfast', 'trứng', 100),
      _PresetTemplateItem('Breakfast', 'bánh mì nguyên cám', 60),
      _PresetTemplateItem('Lunch', 'ức gà', 140),
      _PresetTemplateItem('Lunch', 'rau luộc', 180),
      _PresetTemplateItem('Dinner', 'đậu hũ', 150),
      _PresetTemplateItem('Dinner', 'salad', 180),
      _PresetTemplateItem('Snack', 'sữa chua', 100),
    ],
  ),
  _MealTemplatePreset(
    title: 'Thực đơn tăng cơ',
    description: 'Tăng protein và thêm bữa phụ để hỗ trợ vận động.',
    items: [
      _PresetTemplateItem('Breakfast', 'trứng', 120),
      _PresetTemplateItem('Breakfast', 'yến mạch', 120),
      _PresetTemplateItem('Lunch', 'cơm', 180),
      _PresetTemplateItem('Lunch', 'thịt bò', 140),
      _PresetTemplateItem('Dinner', 'ức gà', 150),
      _PresetTemplateItem('Dinner', 'khoai lang', 150),
      _PresetTemplateItem('Snack', 'chuối', 120),
    ],
  ),
];

String _mealTypeLabel(String value) {
  switch (value.toLowerCase()) {
    case 'breakfast':
      return 'Bữa sáng';
    case 'lunch':
      return 'Bữa trưa';
    case 'dinner':
      return 'Bữa tối';
    default:
      return 'Bữa phụ';
  }
}

int _mealTypeOrder(String value) {
  final index = _mealTypes.indexWhere((type) => type.toLowerCase() == value.toLowerCase());
  return index < 0 ? _mealTypes.length : index;
}

String _itemMealType(MealTemplateItem item, MealTemplate template) {
  final value = item.mealType ?? template.mealType ?? 'Snack';
  return _mealTypes.contains(value) ? value : 'Snack';
}

String _itemLabel(MealTemplateItem item, int index) {
  final name = item.name;
  if (name != null && name.isNotEmpty) return '$name (gram)';
  return 'Món ${index + 1} (gram)';
}

String _templateTypeLabel(MealTemplate template) {
  if ((template.mealType ?? '').toLowerCase() == 'daily') return 'Thực đơn ngày';
  return _mealTypeLabel(template.mealType ?? 'Snack');
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

void _disposeControllers(Iterable<TextEditingController> controllers) {
  for (final controller in controllers) {
    controller.dispose();
  }
}
