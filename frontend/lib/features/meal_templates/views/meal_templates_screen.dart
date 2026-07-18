import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../models/meal_template_models.dart';
import '../repositories/meal_template_repository.dart';

part 'meal_template_editor_part.dart';
part 'meal_template_widgets_part.dart';
part 'meal_template_picker_part.dart';

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
                    child: const Text('Dùng mẫu bữa ăn này'),
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
      appBar: AppBar(title: const Text('Mẫu bữa ăn')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tạo mẫu bữa ăn',
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
                      Center(child: Text('Chưa có mẫu bữa ăn nào.')),
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
                                tooltip: 'Dùng mẫu bữa ăn',
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
