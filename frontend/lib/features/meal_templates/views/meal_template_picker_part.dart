part of 'meal_templates_screen.dart';

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
              initialValue: _mealType,
              decoration: const InputDecoration(labelText: 'Nhóm bữa'),
              items: _mealTypes.map((type) => DropdownMenuItem(value: type, child: Text(_mealTypeLabel(type)))).toList(),
              onChanged: (value) => setState(() => _mealType = value ?? widget.initialMealType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _source,
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
                initialValue: _selectedId,
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




