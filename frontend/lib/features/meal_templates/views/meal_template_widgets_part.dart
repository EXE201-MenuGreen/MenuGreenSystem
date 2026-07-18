part of 'meal_templates_screen.dart';

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


