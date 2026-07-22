part of 'meal_templates_screen.dart';

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
              customName: item.customName,
              sourceType: item.sourceType,
              mealType: item.mealType ?? template.mealType ?? 'Snack',
              label: label,
              quantityG: item.quantityG,
              notes: item.notes,
              caloriesKcal: item.caloriesKcal,
              proteinG: item.proteinG,
              carbsG: item.carbsG,
              fatG: item.fatG,
              ingredients: item.ingredients,
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
    final updated = await showModalBottomSheet<MealTemplateDraftItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditTemplateItemSheet(original: original),
    );

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
      appBar: AppBar(
        title: Text(
          widget.template == null
              ? 'Tạo mẫu bữa ăn'
              : 'Chỉnh sửa mẫu bữa ăn',
        ),
      ),
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

class _EditTemplateItemSheet extends StatefulWidget {
  const _EditTemplateItemSheet({required this.original});

  final MealTemplateDraftItem original;

  @override
  State<_EditTemplateItemSheet> createState() => _EditTemplateItemSheetState();
}

class _EditTemplateItemSheetState extends State<_EditTemplateItemSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.original.quantityG.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: widget.original.notes ?? '');
    _mealType = widget.original.mealType;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;
    final original = widget.original;
    final scale = original.quantityG > 0 ? quantity / original.quantityG : 1.0;
    double? scaled(double? value) => value == null ? null : value * scale;

    Navigator.pop(
      context,
      MealTemplateDraftItem(
        foodId: original.foodId,
        recipeId: original.recipeId,
        customName: original.customName,
        sourceType: original.sourceType,
        mealType: _mealType,
        label: original.label,
        quantityG: quantity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        caloriesKcal: scaled(original.caloriesKcal),
        proteinG: scaled(original.proteinG),
        carbsG: scaled(original.carbsG),
        fatG: scaled(original.fatG),
        ingredients: original.ingredients
            .map(
              (item) => MealTemplateIngredient(
                name: item.name,
                quantity: item.quantity * scale,
                unit: item.unit,
                isAvailable: item.isAvailable,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.original;
    return SafeArea(
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
            if (original.ingredients.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AiScanDishDetailScreen(
                          dishName: original.label,
                          ingredients: original.ingredients,
                          quantityG: original.quantityG,
                          caloriesKcal: original.caloriesKcal ?? 0,
                          proteinG: original.proteinG ?? 0,
                          carbsG: original.carbsG ?? 0,
                          fatG: original.fatG ?? 0,
                          sourceType: original.sourceType,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Xem chi tiết nguyên liệu'),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _mealType,
              decoration: const InputDecoration(labelText: 'Nhóm bữa'),
              items: _mealTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(_mealTypeLabel(type))))
                  .toList(),
              onChanged: (value) => setState(() => _mealType = value ?? original.mealType),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Khối lượng (gram)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onSubmit,
                child: const Text('Cập nhật món'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

