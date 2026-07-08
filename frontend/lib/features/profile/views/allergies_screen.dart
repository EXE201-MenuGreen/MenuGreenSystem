import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/repositories/allergy_repository.dart';

class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  final _repository = AllergyRepository();

  final Set<String> _selected = {};
  List<AllergyItem> _existing = [];
  List<AllergyCatalogItem> _catalog = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repository.getAll();
      var catalog = <AllergyCatalogItem>[];
      try {
        catalog = await _repository.getCatalog();
      } catch (_) {
        catalog = [];
      }
      if (!mounted) return;
      setState(() {
        _existing = items;
        _catalog = catalog;
        _selected
          ..clear()
          ..addAll(items.where((e) => e.isActive).map((e) => e.name));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final existing = await _repository.getAll();
      final currentNames = existing.map((e) => e.name).toSet();

      for (final name in _selected) {
        if (!currentNames.contains(name)) {
          await _repository.create(name);
        }
      }
      for (final item in existing) {
        if (!_selected.contains(item.name)) {
          await _repository.delete(item.id);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu danh sách dị ứng'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu dị ứng, vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addCustomAllergy() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm dị ứng'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tên thực phẩm / dị ứng'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(ctx, value);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    setState(() => _selected.add(name));
  }

  IconData _iconForAllergy({String? key, required String name}) {
    switch (key) {
      case 'seafood':
        return Icons.set_meal_outlined;
      case 'peanut':
        return Icons.circle_outlined;
      case 'dairy':
        return Icons.water_drop_outlined;
      case 'gluten':
        return Icons.grass_outlined;
      case 'egg':
        return Icons.egg_outlined;
      case 'soy':
        return Icons.eco_outlined;
      case 'wheat':
        return Icons.breakfast_dining_outlined;
      case 'tree_nut':
        return Icons.park_outlined;
    }

    final normalized = name.toLowerCase();
    if (normalized.contains('seafood') || normalized.contains('hai san')) {
      return Icons.set_meal_outlined;
    }
    if (normalized.contains('peanut') || normalized.contains('dau phong')) {
      return Icons.circle_outlined;
    }
    if (normalized.contains('milk') ||
        normalized.contains('dairy') ||
        normalized.contains('lactose')) {
      return Icons.water_drop_outlined;
    }
    if (normalized.contains('gluten')) return Icons.grass_outlined;
    if (normalized.contains('egg') || normalized.contains('trung')) {
      return Icons.egg_outlined;
    }
    if (normalized.contains('soy') || normalized.contains('dau nanh')) {
      return Icons.eco_outlined;
    }
    if (normalized.contains('wheat') || normalized.contains('lua mi')) {
      return Icons.breakfast_dining_outlined;
    }
    if (normalized.contains('nut') || normalized.contains('hat cay')) {
      return Icons.park_outlined;
    }
    return Icons.warning_amber_outlined;
  }

  List<Map<String, dynamic>> get _allItems {
    final itemsByName = <String, Map<String, dynamic>>{};
    for (final item in _catalog) {
      itemsByName[item.displayNameVi] = {
        'name': item.displayNameVi,
        'key': item.key,
        'icon': _iconForAllergy(key: item.key, name: item.displayNameVi),
      };
    }
    for (final name in _selected) {
      itemsByName.putIfAbsent(
        name,
        () => {
          'name': name,
          'key': '',
          'icon': _iconForAllergy(name: name),
        },
      );
    }
    return itemsByName.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Dị ứng thực phẩm',
          style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dị ứng của bạn', style: AppTextStyles.heading1),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn hoặc thêm thực phẩm bạn dị ứng để gợi ý món ăn an toàn hơn.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: _allItems.length,
                    itemBuilder: (context, index) {
                      final item = _allItems[index];
                      final name = item['name'] as String;
                      final isSelected = _selected.contains(name);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.remove(name);
                            } else {
                              _selected.add(name);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.progressBackground,
                              width: isSelected ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      item['icon'] as IconData,
                                      color: isSelected ? AppColors.primary : AppColors.textDark,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected ? AppColors.primary : AppColors.textDark,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _addCustomAllergy,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.progressBackground),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline, color: AppColors.textDark),
                          SizedBox(width: 8),
                          Text(
                            'Thêm loại dị ứng khác...',
                            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_existing.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Đã lưu: ${_existing.where((e) => e.isActive).length} mục',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                    onPressed: _saving ? () {} : _save,
                  ),
                ],
              ),
            ),
    );
  }
}
