import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../repositories/allergy_repository.dart';
import '../../repositories/user_ai_profile_repository.dart';

class AllergiesStep extends StatefulWidget {
  final VoidCallback onNext;
  final UserAiProfileRepository? userAiProfileRepository;
  const AllergiesStep({
    super.key,
    required this.onNext,
    this.userAiProfileRepository,
  });

  @override
  State<AllergiesStep> createState() => _AllergiesStepState();
}

class _AllergiesStepState extends State<AllergiesStep> {
  final _repository = AllergyRepository();
  final List<Map<String, dynamic>> _allergies = [
    {'name': 'Hải sản', 'icon': Icons.set_meal_outlined},
    {'name': 'Đậu phộng', 'icon': Icons.circle_outlined},
    {'name': 'Sữa', 'icon': Icons.water_drop_outlined},
    {'name': 'Gluten', 'icon': Icons.grass_outlined},
    {'name': 'Trứng', 'icon': Icons.egg_outlined},
    {'name': 'Đậu nành', 'icon': Icons.eco_outlined},
    {'name': 'Lúa mì', 'icon': Icons.breakfast_dining_outlined},
    {'name': 'Hạt cây', 'icon': Icons.park_outlined},
  ];

  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingAllergies();
  }

  Future<void> _loadExistingAllergies() async {
    try {
      final items = await _repository.getAll().timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        _selected
          ..clear()
          ..addAll(
            items.where((item) => item.isActive).map((item) => item.name),
          );
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _skipAllergies() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (widget.userAiProfileRepository != null) {
        await widget.userAiProfileRepository!
            .upsert(allergiesAcknowledged: true)
            .timeout(const Duration(seconds: 12));
      }
      widget.onNext();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể bỏ qua bước này, vui lòng thử lại.')),
        );
      }
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

  Future<void> _saveAndContinue() async {
    if (_saving) return;
    setState(() => _saving = true);

    var success = false;
    try {
      final existing = await _repository.getAll();
      final currentNames = existing.map((item) => item.name).toSet();

      for (final name in _selected) {
        if (!currentNames.contains(name)) {
          final created = await _repository.create(name);
          if (!created) {
            throw Exception('create allergy failed');
          }
        }
      }

      for (final item in existing) {
        if (!_selected.contains(item.name)) {
          final deleted = await _repository.delete(item.id);
          if (!deleted) {
            throw Exception('delete allergy failed');
          }
        }
      }

      if (_selected.isEmpty && widget.userAiProfileRepository != null) {
        final ack = await widget.userAiProfileRepository!
            .upsert(allergiesAcknowledged: true)
            .timeout(const Duration(seconds: 12));
        if (!ack.success) {
          throw Exception(ack.message);
        }
      }

      success = true;
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu dị ứng quá thời gian, vui lòng thử lại.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu dị ứng, vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (success && mounted) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bạn có bị dị ứng không?', style: AppTextStyles.heading1),
          const SizedBox(height: 8),
          const Text('Hãy chọn các loại thực phẩm bạn bị dị ứng để chúng tôi cá nhân hóa thực đơn an toàn cho bạn.', style: AppTextStyles.subtitle),
          const SizedBox(height: 32),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
            ),
            itemCount: _allergies.length,
            itemBuilder: (context, index) {
              final item = _allergies[index];
              final isSelected = _selected.contains(item['name']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected ? _selected.remove(item['name']) : _selected.add(item['name']);
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
                            Icon(item['icon'], color: isSelected ? AppColors.primary : AppColors.textDark),
                            const SizedBox(height: 4),
                            Text(item['name'], style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
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
                  Text('Thêm loại dị ứng khác...', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _saving || _loading ? null : _skipAllergies,
            child: const Text(
              'Tôi không bị dị ứng',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: _saving ? 'Đang lưu...' : 'Tiếp tục  →',
            onPressed: _saving || _loading ? null : _saveAndContinue,
          ),
        ],
      ),
    );
  }
}
