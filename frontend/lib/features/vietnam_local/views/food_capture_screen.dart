import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator_fixed.dart';
import '../providers/food_capture_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';

/// Real-world food data capture — `2.14 Food Capture ("Ăn ngoài?")`.
///
/// Allows the user to log a meal manually when no Food/Recipe matches the
/// restaurant item they just ate. Posts the request to
/// `/api/Nutrition/food-capture/fallback-estimate` which delegates to
/// `MealLogUpsert`.
class FoodCaptureScreen extends StatefulWidget {
  const FoodCaptureScreen({super.key});

  @override
  State<FoodCaptureScreen> createState() => _FoodCaptureScreenState();
}

class _FoodCaptureScreenState extends State<FoodCaptureScreen> {
  static const _mealTypes = <String>['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _notesController;
  String _mealType = 'Snack';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool saveAsQuickAdd}) async {
    final provider = context.read<FoodCaptureProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final calories = double.tryParse(_caloriesController.text.trim());
    if (calories == null || calories <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập calo ước tính.')),
      );
      return;
    }
    final payload = <String, dynamic>{
      'mealType': _mealType,
      'quantityG': 100,
      'caloriesKcal': calories,
      'proteinG': double.tryParse(_proteinController.text.trim()) ?? 0,
      'carbsG': double.tryParse(_carbsController.text.trim()) ?? 0,
      'fatG': double.tryParse(_fatController.text.trim()) ?? 0,
      'notes': _notesController.text.trim().isEmpty
          ? (_nameController.text.trim().isEmpty
              ? 'Ăn ngoài - ước tính'
              : _nameController.text.trim())
          : _notesController.text.trim(),
      'loggedAt': DateTime.now().toIso8601String(),
    };
    final result = saveAsQuickAdd
        ? await provider.saveAsQuickAdd(payload)
        : await provider.fallbackEstimate(payload);
    if (!mounted) return;
    if (result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saveAsQuickAdd
                ? 'Đã lưu thành món ăn nhanh.'
                : 'Đã ghi nhật ký bữa ăn ước tính.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ApiMessageTranslator.translate(result.message)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ăn ngoài?',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Consumer<FoodCaptureProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Ước tính calo khi ăn ngoài',
                    icon: Icons.no_food_outlined,
                    subtitle:
                        'Không tìm được món chính xác? Nhập nhanh calo ước tính để ghi nhật ký.',
                  ),
                  const SizedBox(height: 16),
                  InfoCard(
                    icon: Icons.lightbulb_outline,
                    title: 'Mẹo ước lượng',
                    footnote:
                        'Bữa chính ngoài quán thường dao động 450–700 kcal. '
                        'Phụ thêm nước sốt/dầu ~50–100 kcal. '
                        'Đồ uống có đường thường 100–200 kcal/ly.',
                  ),
                  const SizedBox(height: 16),
                  _field('Tên món (tuỳ chọn)', _nameController),
                  const SizedBox(height: 12),
                  const Text(
                    'Bữa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _mealTypes
                        .map(
                          (e) => ChoiceChip(
                            label: Text(_mealLabel(e)),
                            selected: _mealType == e,
                            onSelected: (_) => setState(() => _mealType = e),
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    'Calo ước tính (kcal)',
                    _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Protein (g)',
                          _proteinController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Carbs (g)',
                          _carbsController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'Fat (g)',
                    _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  _field('Ghi chú', _notesController, minLines: 2, maxLines: 3),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () => _submit(saveAsQuickAdd: true),
                          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                          label: const Text('Lưu Quick-add'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.isLoading
                              ? null
                              : () => _submit(saveAsQuickAdd: false),
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_alt, size: 18),
                          label: const Text('Ghi nhật ký'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool required = false,
    int minLines = 1,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        filled: true,
        fillColor: AppColors.progressBackground.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _mealLabel(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return 'Sáng';
      case 'Lunch':
        return 'Trưa';
      case 'Dinner':
        return 'Tối';
      default:
        return 'Phụ';
    }
  }
}
