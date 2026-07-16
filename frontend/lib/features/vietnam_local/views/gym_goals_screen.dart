import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator.dart';
import '../../subscription/repositories/user_subscription_repository.dart';
import '../../subscription/widgets/premium_paywall_widget.dart';
import '../models/vietnam_local_models.dart';
import '../providers/gym_goals_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';

/// Gym/PT Goal workflow — `2.13 Gym/PT Goal-Based Workflow`.
class GymGoalsScreen extends StatefulWidget {
  const GymGoalsScreen({super.key});

  @override
  State<GymGoalsScreen> createState() => _GymGoalsScreenState();
}

class _GymGoalsScreenState extends State<GymGoalsScreen> {
  final _subRepo = UserSubscriptionRepository();
  bool _subLoading = true;
  bool _hasProAccess = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    setState(() {
      _subLoading = true;
    });

    try {
      final sub = await _subRepo.getCurrent();
      final planName = sub?.subscriptionPlanName.toLowerCase() ?? '';
      final hasAccess =
          sub != null &&
          sub.isActive &&
          sub.daysRemaining >= 0 &&
          (planName.contains('gym') || planName.contains('pro'));

      setState(() {
        _hasProAccess = hasAccess;
        _subLoading = false;
      });

      if (hasAccess) {
        _loadGymData();
      }
    } catch (_) {
      setState(() {
        _hasProAccess = false;
        _subLoading = false;
      });
    }
  }

  void _loadGymData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<GymGoalsProvider>();
      await provider.loadProfile();
      if (!mounted) return;
      await provider.loadPlan(top: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chế độ Gym / PT',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: _subLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : !_hasProAccess
            ? const PremiumPaywallWidget(
                featureName: 'Chế độ Gym / PT',
                featureDescription:
                    'Kích hoạt gói Gym/PT để dùng mục tiêu calo, protein và lịch tập chuyên biệt.',
              )
            : Consumer<GymGoalsProvider>(
                builder: (context, provider, _) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      await provider.loadProfile();
                      await provider.loadPlan(top: 10);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        InfoCard(
                          icon: Icons.fitness_center,
                          title: _goalLabel(
                            provider.profile?.goalMode ?? 'maintain',
                          ),
                          subtitle: _scheduleSummary(provider.profile),
                          value: _calorieSummary(provider.profile),
                          footnote:
                              'Ngưỡng an toàn: tối thiểu 1200 kcal/ngày (theo NHS).',
                          trailing: TextButton(
                            onPressed: () =>
                                _openEditor(context, provider.profile),
                            child: const Text('Cấu hình'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecalibrateCard(provider),
                        const SizedBox(height: 24),
                        const SectionHeader(
                          title: 'Gợi ý thực đơn cho hôm nay',
                          icon: Icons.restaurant_menu,
                          subtitle: 'Dựa trên chế độ gym và calo mục tiêu',
                        ),
                        const SizedBox(height: 12),
                        _buildPlanList(provider),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 16),
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
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _goalLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'cut':
        return 'Cắt giảm mỡ (Cut)';
      case 'bulk':
        return 'Tăng cơ (Bulk)';
      case 'recomp':
        return 'Tái cấu trúc cơ thể (Recomp)';
      case 'maintain':
      default:
        return 'Duy trì (Maintain)';
    }
  }

  String _scheduleSummary(GymGoalProfile? p) {
    if (p == null) return 'Đang tải cấu hình...';
    final schedule = p.weeklyTrainingSchedule.trim();
    if (schedule.isEmpty) return 'Chưa thiết lập lịch tập';
    return 'Ngày tập: $schedule'
        '${p.restDaysPerWeek != null ? ' • Nghỉ ${p.restDaysPerWeek} ngày/tuần' : ''}';
  }

  String _calorieSummary(GymGoalProfile? p) {
    if (p == null) return '—';
    final train = p.trainingDayTargetCalories;
    final rest = p.restDayTargetCalories;
    if (train == null && rest == null) return 'Chưa thiết lập';
    return 'Tập: ${train ?? '—'} kcal • Nghỉ: ${rest ?? '—'} kcal';
  }

  Widget _buildRecalibrateCard(GymGoalsProvider provider) {
    final last = provider.lastRecalibration;
    return InfoCard(
      icon: Icons.tune,
      title: 'Hiệu chỉnh mục tiêu',
      subtitle: last == null
          ? 'Đánh giá cân nặng tuần qua và điều chỉnh calo tự động.'
          : 'Gợi ý hiện tại: ${last.suggestedTargetCalories} kcal',
      footnote: last == null
          ? null
          : ApiMessageTranslator.translate(last.reason),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: provider.isRecalibrating ? null : provider.recalibrate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: provider.isRecalibrating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text(
            'Hiệu chỉnh ngay',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanList(GymGoalsProvider provider) {
    if (provider.isLoading && provider.planSuggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (provider.planSuggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.progressBackground),
        ),
        child: const Text(
          'Chưa có gợi ý thực đơn. Hãy lưu cấu hình gym trước.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        for (final item in provider.planSuggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.progressBackground),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.type.toLowerCase().contains('recipe')
                          ? Icons.menu_book
                          : Icons.restaurant,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name.isEmpty ? 'Món gợi ý' : item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.caloriesKcal.toStringAsFixed(0)} kcal • '
                          'P ${item.proteinG.toStringAsFixed(0)}g • '
                          'Điểm ${item.score.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    GymGoalProfile? profile,
  ) async {
    final updated = await Navigator.push<GymGoalProfile?>(
      context,
      MaterialPageRoute(builder: (_) => GymGoalsEditorScreen(initial: profile)),
    );
    if (updated != null && context.mounted) {
      final provider = context.read<GymGoalsProvider>();
      final ok = await provider.save(updated);
      if (!ok) return;
      await provider.loadPlan(top: 10);
    }
  }
}

class GymGoalsEditorScreen extends StatefulWidget {
  const GymGoalsEditorScreen({super.key, this.initial});

  final GymGoalProfile? initial;

  @override
  State<GymGoalsEditorScreen> createState() => _GymGoalsEditorScreenState();
}

class _GymGoalsEditorScreenState extends State<GymGoalsEditorScreen> {
  static const _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late final Set<String> _selectedDays;
  late String _goalMode;
  late final TextEditingController _trainCal;
  late final TextEditingController _restCal;
  late final TextEditingController _minCal;
  late final TextEditingController _maxCal;
  late final TextEditingController _minProtein;
  late final TextEditingController _maxProtein;
  late final TextEditingController _trainCount;
  late final TextEditingController _restCount;
  late final TextEditingController _notes;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _selectedDays = (init?.weeklyTrainingSchedule ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    _goalMode = init?.goalMode ?? 'maintain';
    _trainCal = TextEditingController(
      text: (init?.trainingDayTargetCalories ?? '').toString(),
    );
    _restCal = TextEditingController(
      text: (init?.restDayTargetCalories ?? '').toString(),
    );
    _minCal = TextEditingController(
      text: (init?.minCalories ?? 1200).toString(),
    );
    _maxCal = TextEditingController(
      text: (init?.maxCalories ?? 3500).toString(),
    );
    _minProtein = TextEditingController(
      text: (init?.minProteinG ?? 80).toString(),
    );
    _maxProtein = TextEditingController(
      text: (init?.maxProteinG ?? 220).toString(),
    );
    _trainCount = TextEditingController(
      text: (init?.trainingDaysPerWeek ?? 3).toString(),
    );
    _restCount = TextEditingController(
      text: (init?.restDaysPerWeek ?? 4).toString(),
    );
    _notes = TextEditingController(text: init?.notes ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _initializing = false);
    });
  }

  @override
  void dispose() {
    _trainCal.dispose();
    _restCal.dispose();
    _minCal.dispose();
    _maxCal.dispose();
    _minProtein.dispose();
    _maxProtein.dispose();
    _trainCount.dispose();
    _restCount.dispose();
    _notes.dispose();
    super.dispose();
  }

  GymGoalProfile _build() {
    return GymGoalProfile(
      goalMode: _goalMode,
      weeklyTrainingSchedule: _selectedDays.join(','),
      trainingDaysPerWeek: int.tryParse(_trainCount.text.trim()),
      restDaysPerWeek: int.tryParse(_restCount.text.trim()),
      trainingDayTargetCalories: int.tryParse(_trainCal.text.trim()),
      restDayTargetCalories: int.tryParse(_restCal.text.trim()),
      minCalories: int.tryParse(_minCal.text.trim()),
      maxCalories: int.tryParse(_maxCal.text.trim()),
      minProteinG: int.tryParse(_minProtein.text.trim()),
      maxProteinG: int.tryParse(_maxProtein.text.trim()),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
          'Cấu hình gym',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop<GymGoalProfile?>(context, _build()),
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chế độ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['cut', 'maintain', 'bulk', 'recomp']
                    .map(
                      (e) => ChoiceChip(
                        label: Text(_label(e)),
                        selected: _goalMode.toLowerCase() == e,
                        onSelected: (_) => setState(() => _goalMode = e),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lịch tập trong tuần',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _days
                    .map(
                      (e) => FilterChip(
                        label: Text(_dayLabel(e)),
                        selected: _selectedDays.contains(e),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedDays.add(e);
                          } else {
                            _selectedDays.remove(e);
                          }
                        }),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField('Ngày tập/tuần', _trainCount),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField('Ngày nghỉ/tuần', _restCount),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField('Calo ngày tập', _trainCal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField('Calo ngày nghỉ', _restCal),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildNumberField('Calo tối thiểu', _minCal)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNumberField('Calo tối đa', _maxCal)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'Protein tối thiểu (g)',
                      _minProtein,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField('Protein tối đa (g)', _maxProtein),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Ghi chú',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.progressBackground.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _label(String mode) {
    switch (mode) {
      case 'cut':
        return 'Cut';
      case 'bulk':
        return 'Bulk';
      case 'recomp':
        return 'Recomp';
      default:
        return 'Maintain';
    }
  }

  String _dayLabel(String day) {
    const labels = {
      'Monday': 'T2',
      'Tuesday': 'T3',
      'Wednesday': 'T4',
      'Thursday': 'T5',
      'Friday': 'T6',
      'Saturday': 'T7',
      'Sunday': 'CN',
    };
    return labels[day] ?? day;
  }
}
