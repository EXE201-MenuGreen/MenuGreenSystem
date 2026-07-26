import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../models/vietnam_local_models.dart';
import '../providers/local_preferences_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';

/// Local Preferences — `2.11 Vietnam-first Local Nutrition`.
///
/// Wraps `GET/POST/PUT /api/Nutrition/local-preferences` (UserAiProfile proxy).
class LocalPreferencesScreen extends StatefulWidget {
  const LocalPreferencesScreen({super.key});

  @override
  State<LocalPreferencesScreen> createState() => _LocalPreferencesScreenState();
}

class _LocalPreferencesScreenState extends State<LocalPreferencesScreen> {
  static const _regions = <String>['north', 'central', 'south'];
  static const _mealContexts = <String>['eat-out', 'home-cooked', 'mixed'];
  static const _eatingPatterns = <String>['general', 'gym', 'office'];

  late String _region;
  late String _mealContext;
  late String _eatingPattern;
  late final TextEditingController _budgetController;
  late final TextEditingController _portionUnitsController;
  late final TextEditingController _dislikedController;
  bool _initializing = true;
  bool _isPro = false;
  String _subscriptionPlanName = '';

  @override
  void initState() {
    super.initState();
    _region = _regions.last;
    _mealContext = _mealContexts.last;
    _eatingPattern = _eatingPatterns.first;
    _budgetController = TextEditingController();
    _portionUnitsController = TextEditingController();
    _dislikedController = TextEditingController();
    _checkSub();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LocalPreferencesProvider>();
      await provider.load();
      if (!mounted) return;
      _hydrate(provider.profile);
    });
  }

  Future<void> _checkSub() async {
    try {
      final sub = await UserSubscriptionRepository().getCurrent();
      if (sub != null && sub.isActive && sub.daysRemaining >= 0) {
        final planName = sub.subscriptionPlanName.toLowerCase();
        final hasPro = !planName.contains('free') && !planName.contains('cơ bản');
        if (mounted) {
          setState(() {
            _isPro = hasPro;
            _subscriptionPlanName = sub.subscriptionPlanName;
          });
        }
      }
    } catch (_) {}
  }

  void _hydrate(LocalPreferencesProfile? p) {
    _initializing = false;
    if (p == null) {
      setState(() {});
      return;
    }
    setState(() {
      _region = _normalize(p.vietnamRegion, _regions, _regions.last);
      _mealContext = _normalize(
        p.mealContext,
        _mealContexts,
        _mealContexts.last,
      );
      _eatingPattern = _normalize(
        p.eatingPattern,
        _eatingPatterns,
        _eatingPatterns.first,
      );
      _budgetController.text = p.budgetPerMealVnd?.toString() ?? '';
      _portionUnitsController.text = p.preferredPortionUnits ?? '';
      _dislikedController.text = p.dislikedFoods ?? '';
    });
  }

  String _normalize(String? value, List<String> options, String fallback) {
    final lower = value?.toLowerCase() ?? '';
    if (options.contains(lower)) return lower;
    return fallback;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _portionUnitsController.dispose();
    _dislikedController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<LocalPreferencesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.save(
      vietnamRegion: _region,
      mealContext: _mealContext,
      budgetPerMealVnd: int.tryParse(_budgetController.text.trim()),
      preferredPortionUnits: _portionUnitsController.text.trim().isEmpty
          ? null
          : _portionUnitsController.text.trim(),
      eatingPattern: _eatingPattern,
      dislikedFoods: _dislikedController.text.trim().isEmpty
          ? null
          : _dislikedController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu sở thích.')));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không lưu được sở thích.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadBudgetAware() async {
    final provider = context.read<LocalPreferencesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final budget = int.tryParse(_budgetController.text.trim());
    await provider.loadBudgetAware(budgetVnd: budget, top: 10);
    if (!mounted) return;
    if (provider.budgetAware.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa tìm được món phù hợp ngân sách.')),
      );
    } else {
      _showRecList(
        title: 'Gợi ý theo ngân sách',
        items: provider.budgetAware
            .map((e) => '${e.name} • ${e.caloriesKcal.toStringAsFixed(0)} kcal')
            .toList(),
      );
    }
  }

  Future<void> _loadLocalFriendly() async {
    final provider = context.read<LocalPreferencesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.loadLocalFriendly(top: 10);
    if (!mounted) return;
    if (provider.localFriendly.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa tìm được món local-friendly.')),
      );
    } else {
      _showRecList(
        title: 'Món dễ ăn VN',
        items: provider.localFriendly
            .map((e) => '${e.name} • ${e.caloriesKcal.toStringAsFixed(0)} kcal')
            .toList(),
      );
    }
  }

  void _showRecList({required String title, required List<String> items}) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• $e',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sở thích ăn uống',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Consumer<LocalPreferencesProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionHeader(title: 'Vùng miền', icon: Icons.public),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _regions
                      .map(
                        (e) => ChoiceChip(
                          label: Text(_regionLabel(e)),
                          selected: _region == e,
                          onSelected: (_) => setState(() => _region = e),
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                const SectionHeader(
                  title: 'Bối cảnh ăn uống',
                  icon: Icons.restaurant,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _mealContexts
                      .map(
                        (e) => ChoiceChip(
                          label: Text(_mealContextLabel(e)),
                          selected: _mealContext == e,
                          onSelected: (_) => setState(() => _mealContext = e),
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                const SectionHeader(
                  title: 'Phân nhóm người dùng',
                  icon: Icons.group,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _eatingPatterns
                      .map(
                        (e) => ChoiceChip(
                          label: Text(_eatingPatternLabel(e)),
                          selected: _eatingPattern == e,
                          onSelected: (_) {
                            if (_isPro) {
                              final planLower = _subscriptionPlanName.toLowerCase();
                              final isGymPlan = planLower.contains('gym');
                              final isOfficePlan = planLower.contains('office');

                              if (isGymPlan && e != 'gym') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gói Gym/PT hiện tại của bạn chỉ áp dụng cho chế độ Gym / PT.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              if (isOfficePlan && e != 'office') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gói cước của bạn chỉ áp dụng cho chế độ Văn phòng.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                            }
                            setState(() => _eatingPattern = e);
                          },
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Ngân sách mỗi bữa (VND)',
                    filled: true,
                    fillColor: AppColors.progressBackground.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _portionUnitsController,
                  decoration: InputDecoration(
                    labelText: 'Đơn vị ưa thích (vd: chén, bát, muỗng, trái)',
                    filled: true,
                    fillColor: AppColors.progressBackground.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dislikedController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Món không thích (phân cách dấu phẩy)',
                    filled: true,
                    fillColor: AppColors.progressBackground.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (provider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white, size: 18),
                    label: const Text(
                      'Lưu sở thích',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Khám phá gợi ý theo sở thích',
                  icon: Icons.travel_explore,
                ),
                const SizedBox(height: 8),
                _buildShortcut(
                  title: 'Gợi ý theo ngân sách',
                  subtitle: 'Dùng ngân sách đã thiết lập để tìm món phù hợp.',
                  onTap: _loadBudgetAware,
                ),
                _buildShortcut(
                  title: 'Món local-friendly',
                  subtitle: 'Món quen thuộc với khẩu vị Việt.',
                  onTap: _loadLocalFriendly,
                ),
                if (provider.budgetAware.isNotEmpty)
                  InfoCard(
                    icon: Icons.attach_money,
                    title: 'Top theo ngân sách',
                    child: Column(
                      children: provider.budgetAware
                          .take(5)
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${e.name} • ${e.caloriesKcal.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Nhật ký ăn uống VN',
                  icon: Icons.menu_book,
                ),
                const SizedBox(height: 8),
                _buildShortcut(
                  title: 'Gợi ý món VN',
                  subtitle: 'Xem gợi ý món ăn Việt Nam cho bữa tiếp theo.',
                  onTap: () => _showVnMealSuggestions(context),
                ),
                _buildShortcut(
                  title: 'Ghi nhật ký nhanh',
                  subtitle:
                      'Ghi bữa ăn nhanh bằng đơn vị VN (chén, bát, muỗng).',
                  onTap: () => _showQuickLogDialog(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showVnMealSuggestions(BuildContext context) async {
    final provider = context.read<LocalPreferencesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final budget = int.tryParse(_budgetController.text.trim());
    final results = await provider.discoveryLocal(maxPriceVnd: budget);
    if (!context.mounted) return;
    if (results.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không có gợi ý nào.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gợi ý món VN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final item = results[i];
                  final foodName = item['nameVi'] ?? '—';
                  final calories = item['caloriesKcal'];
                  final priceVnd = item['estimatedPriceVnd'] ?? '?';
                  return ListTile(
                    leading: const Icon(
                      Icons.rice_bowl,
                      color: AppColors.primary,
                    ),
                    title: Text(foodName),
                    subtitle: Text(
                      '${calories ?? '?'} kcal • $priceVnd VND',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        final logOk = await provider.createVnMealLog({
                          'foodName': foodName,
                          'mealType': 'lunch',
                          'portionUnits': 'bát',
                          'portionAmount': 1,
                          'estimatedCalories': calories ?? 0,
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              logOk ? 'Đã ghi: $foodName' : 'Không ghi được.',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickLogDialog(BuildContext context) {
    final foodCtrl = TextEditingController();
    final portionCtrl = TextEditingController(text: '1');
    String selectedUnit = 'bát';
    String selectedMeal = 'lunch';
    final units = ['chén', 'bát', 'đĩa', 'mâm', 'muỗng canh', 'kg', 'g'];
    final meals = {
      'breakfast': 'Bữa sáng',
      'lunch': 'Bữa trưa',
      'dinner': 'Bữa tối',
      'snack': 'Ăn vặt',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi bữa ăn nhanh'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodCtrl,
                decoration: const InputDecoration(labelText: 'Tên món ăn'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: portionCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedUnit,
                      decoration: const InputDecoration(labelText: 'Đơn vị'),
                      items: units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) => selectedUnit = v ?? selectedUnit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedMeal,
                decoration: const InputDecoration(labelText: 'Bữa ăn'),
                items: meals.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => selectedMeal = v ?? selectedMeal,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (foodCtrl.text.trim().isEmpty) return;
              final provider = context.read<LocalPreferencesProvider>();
              final ok = await provider.createVnMealLog({
                'foodName': foodCtrl.text.trim(),
                'mealType': selectedMeal,
                'portionUnits': selectedUnit,
                'portionAmount': double.tryParse(portionCtrl.text.trim()) ?? 1,
              });
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Đã ghi bữa ăn.' : 'Không ghi được.'),
                ),
              );
            },
            child: const Text('Ghi'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.progressBackground),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _regionLabel(String value) {
    switch (value) {
      case 'north':
        return 'Miền Bắc';
      case 'central':
        return 'Miền Trung';
      case 'south':
        return 'Miền Nam';
      default:
        return value;
    }
  }

  String _mealContextLabel(String value) {
    switch (value) {
      case 'eat-out':
        return 'Ăn ngoài';
      case 'home-cooked':
        return 'Tự nấu';
      case 'mixed':
        return 'Hỗn hợp';
      default:
        return value;
    }
  }

  String _eatingPatternLabel(String value) {
    switch (value) {
      case 'gym':
        return 'Gym';
      case 'office':
        return 'Văn phòng';
      default:
        return 'Phổ thông';
    }
  }
}
