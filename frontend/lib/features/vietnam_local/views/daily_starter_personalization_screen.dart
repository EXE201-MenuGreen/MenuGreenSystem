import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/vietnam_local_models.dart';
import '../providers/daily_starter_provider.dart';

/// Personalization editor used by the Daily Starter hub.
///
/// Submits to `PUT /DailyStarter/personalization` and falls back to the
/// currently loaded values when fields are empty.
class DailyStarterPersonalizationScreen extends StatefulWidget {
  const DailyStarterPersonalizationScreen({super.key});

  @override
  State<DailyStarterPersonalizationScreen> createState() =>
      _DailyStarterPersonalizationScreenState();
}

class _DailyStarterPersonalizationScreenState
    extends State<DailyStarterPersonalizationScreen> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _dietController;
  bool _initialized = false;

  static const _dietOptions = <String>['Balanced', 'Vegetarian', 'High-Protein', 'Low-Carb'];

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _caloriesController = TextEditingController();
    _dietController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DailyStarterProvider>();
      await provider.refreshPersonalization();
      if (!mounted) return;
      _hydrate(provider.personalization);
    });
  }

  void _hydrate(DailyStarterPersonalization? p) {
    if (p == null || _initialized) return;
    _initialized = true;
    setState(() {
      _heightController.text = p.heightCm?.toStringAsFixed(0) ?? '';
      _weightController.text = p.weightKg?.toStringAsFixed(1) ?? '';
      _caloriesController.text = p.targetCalories?.toStringAsFixed(0) ?? '';
      _dietController.text = p.dietaryPreference ?? _dietOptions.first;
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _dietController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<DailyStarterProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.submitPersonalization(
      heightCm: double.tryParse(_heightController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      targetCalories: double.tryParse(_caloriesController.text.trim()),
      dietaryPreference: _dietController.text.trim().isEmpty
          ? null
          : _dietController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật sở thích.')));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không cập nhật được.'),
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
          'Cá nhân hóa',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Consumer<DailyStarterProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberField(
                    label: 'Chiều cao (cm)',
                    controller: _heightController,
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Cân nặng (kg)',
                    controller: _weightController,
                    allowDecimal: true,
                  ),
                  const SizedBox(height: 16),
                  _buildNumberField(
                    label: 'Calo mục tiêu/ngày',
                    controller: _caloriesController,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chế độ ăn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _dietOptions
                        .map(
                          (e) => ChoiceChip(
                            label: Text(e),
                            selected: _dietController.text == e,
                            onSelected: (_) {
                              setState(() => _dietController.text = e);
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.progressBackground),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dị ứng đã đăng ký: ${provider.personalization?.allergenKeys.length ?? 0}'
                            '. Vào mục Dị ứng ở trang cá nhân để chỉnh sửa.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isPersonalizationLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: provider.isPersonalizationLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Lưu',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    bool allowDecimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          allowDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.progressBackground.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
