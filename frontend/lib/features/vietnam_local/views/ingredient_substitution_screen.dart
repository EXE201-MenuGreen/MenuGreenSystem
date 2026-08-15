import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator_fixed.dart';
import '../models/vietnam_local_models.dart';
import '../providers/ingredient_substitution_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';

/// Ingredient substitution preferences — `2.18 Ingredient Substitution Preference`.
class IngredientSubstitutionScreen extends StatefulWidget {
  const IngredientSubstitutionScreen({super.key});

  @override
  State<IngredientSubstitutionScreen> createState() =>
      _IngredientSubstitutionScreenState();
}

class _IngredientSubstitutionScreenState
    extends State<IngredientSubstitutionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientSubstitutionProvider>().load();
    });
  }

  Future<void> _showAddDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _SubstitutionEditorDialog(),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cấu hình thay thế.')),
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
          'Thay thế nguyên liệu',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm cấu hình'),
      ),
      body: SafeArea(
        child: Consumer<IngredientSubstitutionProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SectionHeader(
                    title: 'Nguyên liệu thay thế ưa thích',
                    icon: Icons.swap_horiz,
                    subtitle:
                        'Hệ thống sẽ ưu tiên thay thế theo cấu hình này trước khi '
                        'áp dụng các thuật toán khác.',
                  ),
                  const SizedBox(height: 12),
                  if (provider.isLoading && provider.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (provider.items.isEmpty)
                    InfoCard(
                      icon: Icons.swap_horiz,
                      title: 'Chưa có cấu hình',
                      subtitle:
                          'Bấm "Thêm cấu hình" để thiết lập nguyên liệu thay thế yêu thích.',
                    )
                  else
                    Column(
                      children: provider.items
                          .map((e) => _buildItem(context, provider, e))
                          .toList(),
                    ),
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
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    IngredientSubstitutionProvider provider,
    IngredientSubstitutePreference item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.progressBackground),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.originalIngredientName.isEmpty ? 'Nguyên liệu' : item.originalIngredientName}'
                  ' → ${item.substituteIngredientName.isEmpty ? 'Thay thế' : item.substituteIngredientName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await provider.remove(item.id);
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Đã xoá cấu hình.'
                            : ApiMessageTranslator.translate(provider.errorMessage),
                      ),
                      backgroundColor: ok ? AppColors.primary : Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildChip(_reasonLabel(item.reason)),
              if (item.maxPriceVnd != null)
                _buildChip('≤ ${item.maxPriceVnd} VND'),
              if (item.macroMatch) _buildChip('Khớp macro'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'allergy':
        return 'Dị ứng';
      case 'expensive':
        return 'Giá cao';
      default:
        return 'Không có sẵn';
    }
  }
}

class _SubstitutionEditorDialog extends StatefulWidget {
  const _SubstitutionEditorDialog();

  @override
  State<_SubstitutionEditorDialog> createState() =>
      _SubstitutionEditorDialogState();
}

class _SubstitutionEditorDialogState extends State<_SubstitutionEditorDialog> {
  static const _reasons = <String>['allergy', 'not_available', 'expensive'];

  static const _presetIngredients = [
    (id: 'ing_tom', name: 'Tôm tươi'),
    (id: 'ing_thit_heo', name: 'Thịt heo'),
    (id: 'ing_thit_bo', name: 'Thịt bò'),
    (id: 'ing_ca_hoi', name: 'Cá hồi'),
    (id: 'ing_sua_bo', name: 'Sữa bò'),
    (id: 'ing_trung_ga', name: 'Trứng gà'),
    (id: 'ing_dau_hu', name: 'Đậu hũ'),
    (id: 'ing_uc_ga', name: 'Ức gà'),
    (id: 'ing_cai_ngot', name: 'Cải ngọt'),
    (id: 'ing_sua_hat', name: 'Sữa hạt'),
    (id: 'ing_ca_thu', name: 'Cá thu'),
    (id: 'ing_gao_lut', name: 'Gạo lứt'),
  ];

  late final TextEditingController _customOriginalController;
  late final TextEditingController _customSubstituteController;
  late final TextEditingController _maxPriceController;

  String? _selectedOriginalId;
  String? _selectedSubstituteId;

  String _reason = _reasons.last;
  bool _macroMatch = false;

  @override
  void initState() {
    super.initState();
    _customOriginalController = TextEditingController();
    _customSubstituteController = TextEditingController();
    _maxPriceController = TextEditingController();

    _selectedOriginalId = _presetIngredients[0].id;
    _selectedSubstituteId = _presetIngredients[7].id; // Default: Ức gà
  }

  @override
  void dispose() {
    _customOriginalController.dispose();
    _customSubstituteController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  String _getIngredientName(String? id, String customText) {
    if (id == 'custom') return customText.trim();
    final item = _presetIngredients.firstWhere(
      (e) => e.id == id,
      orElse: () => (id: 'custom', name: customText),
    );
    return item.name;
  }

  Future<void> _save() async {
    final origName = _getIngredientName(_selectedOriginalId, _customOriginalController.text);
    final subName = _getIngredientName(_selectedSubstituteId, _customSubstituteController.text);

    if (origName.isEmpty || subName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hoặc nhập tên nguyên liệu gốc và thay thế.')),
      );
      return;
    }

    final origId = _selectedOriginalId == 'custom'
        ? 'ing_${origName.toLowerCase().replaceAll(' ', '_')}'
        : (_selectedOriginalId ?? 'ing_orig');
    final subId = _selectedSubstituteId == 'custom'
        ? 'ing_${subName.toLowerCase().replaceAll(' ', '_')}'
        : (_selectedSubstituteId ?? 'ing_sub');

    final ok = await context.read<IngredientSubstitutionProvider>().add(
          originalIngredientId: origId,
          originalIngredientName: origName,
          substituteIngredientId: subId,
          substituteIngredientName: subName,
          reason: _reason,
          maxPriceVnd: int.tryParse(_maxPriceController.text.trim()),
          macroMatch: _macroMatch,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<IngredientSubstitutionProvider>().errorMessage ??
                'Không lưu được cấu hình.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm cấu hình thay thế'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Original Ingredient Selector
            const Text(
              'Nguyên liệu gốc (cần đổi)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedOriginalId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                ..._presetIngredients.map(
                  (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                ),
                const DropdownMenuItem(value: 'custom', child: Text('+ Nhập tên nguyên liệu khác')),
              ],
              onChanged: (val) => setState(() => _selectedOriginalId = val),
            ),
            if (_selectedOriginalId == 'custom') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customOriginalController,
                decoration: InputDecoration(
                  labelText: 'Tên nguyên liệu gốc',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 2. Substitute Ingredient Selector
            const Text(
              'Nguyên liệu thay thế mới',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubstituteId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                ..._presetIngredients.map(
                  (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                ),
                const DropdownMenuItem(value: 'custom', child: Text('+ Nhập tên nguyên liệu khác')),
              ],
              onChanged: (val) => setState(() => _selectedSubstituteId = val),
            ),
            if (_selectedSubstituteId == 'custom') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customSubstituteController,
                decoration: InputDecoration(
                  labelText: 'Tên nguyên liệu thay thế',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 3. Max price
            TextField(
              controller: _maxPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Trần giá tối đa (VND, tùy chọn)',
                hintText: 'Ví dụ: 150000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            // 4. Reason
            const Text(
              'Lý do thay thế',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: _reasons
                  .map(
                    (e) => ChoiceChip(
                      label: Text(_reasonLabel(e)),
                      selected: _reason == e,
                      onSelected: (_) => setState(() => _reason = e),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),

            // 5. Macro match
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Khớp dinh dưỡng (Macro)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Quy đổi khẩu phần để giữ nguyên Calo/Protein'),
              value: _macroMatch,
              onChanged: (v) => setState(() => _macroMatch = v),
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'allergy':
        return 'Dị ứng';
      case 'expensive':
        return 'Giá cao';
      default:
        return 'Không có sẵn';
    }
  }
}
