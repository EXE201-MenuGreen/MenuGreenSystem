import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/repositories/profile_repository.dart';
import '../repositories/advanced_repository.dart';
import '../utils/weekly_report_rules.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../vietnam_local/repositories/vietnam_local_repositories.dart';
import 'advanced_detail_screens.dart';
import 'weekly_report_preview_screen.dart';

class AdvancedFeaturesScreen extends StatelessWidget {
  const AdvancedFeaturesScreen({
    super.key,
    this.gymerOnly = false,
    this.initialIndex = 0,
    this.initialReportId,
    this.repository,
    this.reportAnalyticsRepository,
  });

  final bool gymerOnly;
  final int initialIndex;
  final String? initialReportId;
  final AdvancedRepository? repository;
  final PlannedVsActualRepository? reportAnalyticsRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: gymerOnly
          ? Future.value(null)
          : ProfileRepository().getMyProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final role = (profile?['role'] ?? profile?['Role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final isAdmin = role == 'admin';
        final tabs = gymerOnly
            ? const [Tab(text: 'PT Review'), Tab(text: 'Huấn luyện viên')]
            : <Tab>[
                const Tab(text: 'PT Review'),
                const Tab(text: 'Ngân sách'),
                const Tab(text: 'Coach'),
                const Tab(text: 'Nguyên liệu'),
                if (isAdmin) const Tab(text: 'Người dùng'),
              ];
        final tabCount = tabs.length;
        final safeInitialIndex = initialIndex.clamp(0, tabCount - 1);
        return DefaultTabController(
          length: tabCount,
          initialIndex: safeInitialIndex,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAF9),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                gymerOnly ? 'Đồng hành Gym / PT' : 'Dịch vụ & quản lý',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              bottom: TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: tabs,
              ),
            ),
            body: TabBarView(
              children: gymerOnly
                  ? [
                      _PtTab(
                        initialReportId: initialReportId,
                        repository: repository,
                        reportAnalyticsRepository: reportAnalyticsRepository,
                      ),
                      const _CoachTab(gymerMode: true),
                    ]
                  : [
                      _PtTab(
                        initialReportId: initialReportId,
                        repository: repository,
                        reportAnalyticsRepository: reportAnalyticsRepository,
                      ),
                      const _BudgetTab(),
                      const _CoachTab(),
                      const _IngredientTab(),
                      if (isAdmin) const _UserTab(),
                    ],
            ),
          ),
        );
      },
    );
  }
}

String _v(Map<String, dynamic> m, String key, [String fallback = '']) =>
    _readValue(m, key, fallback).toString();

dynamic _readValue(Map<String, dynamic> m, String key, [dynamic fallback]) {
  final variants = <String>[
    key,
    key[0].toUpperCase() + key.substring(1),
    key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    ),
    key.toLowerCase(),
  ];
  for (final candidate in variants) {
    if (m.containsKey(candidate) && m[candidate] != null) {
      return m[candidate];
    }
  }
  return fallback;
}

String _weeklyDateRangeLabel(String rawWeekStart) {
  final weekStart = DateTime.tryParse(rawWeekStart.trim());
  if (weekStart == null) return rawWeekStart;

  final weekEnd = weekStart.add(const Duration(days: 6));
  String fullDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  return '${fullDate(weekStart)} - ${fullDate(weekEnd)}';
}

void _notice(BuildContext c, Object value) =>
    ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(content: Text(value.toString().replaceFirst('Exception: ', ''))),
    );

class _WeeklyCheckInData {
  const _WeeklyCheckInData({
    required this.weight,
    required this.bodyFat,
    required this.trainingDays,
    required this.feeling,
    required this.note,
  });

  final double weight;
  final double? bodyFat;
  final int trainingDays;
  final String feeling;
  final String note;
}

class _WeeklyCheckInDialog extends StatefulWidget {
  const _WeeklyCheckInDialog();

  @override
  State<_WeeklyCheckInDialog> createState() => _WeeklyCheckInDialogState();
}

class _WeeklyCheckInDialogState extends State<_WeeklyCheckInDialog> {
  final _noteController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  int _selectedDays = 3;
  String _selectedFeeling = 'Khỏe 😊';

  @override
  void dispose() {
    _noteController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text.trim());
    final bodyFatText = _bodyFatController.text.trim();
    final bodyFat = bodyFatText.isEmpty ? null : double.tryParse(bodyFatText);
    if (weight == null || weight < 20 || weight > 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cân nặng phải nằm trong khoảng 20–400 kg'),
        ),
      );
      return;
    }
    if (bodyFatText.isNotEmpty &&
        (bodyFat == null || bodyFat < 1 || bodyFat > 75)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tỷ lệ mỡ phải nằm trong khoảng 1–75%')),
      );
      return;
    }

    Navigator.of(context).pop(
      _WeeklyCheckInData(
        weight: weight,
        bodyFat: bodyFat,
        trainingDays: _selectedDays,
        feeling: _selectedFeeling,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Báo cáo & Check-in Tuần',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Điền chỉ số thực tế tuần qua gửi PT',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              _buildFieldLabel('Cân nặng hiện tại (kg)', isRequired: true),
              const SizedBox(height: 6),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: _inputDecoration(
                  hintText: 'Ví dụ: 68.5',
                  prefixIcon: Icons.monitor_weight_outlined,
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Tỷ lệ mỡ (%)', isOptional: true),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: _inputDecoration(
                  hintText: 'Ví dụ: 15.2',
                  prefixIcon: Icons.pie_chart_outline_rounded,
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Số buổi đã tập tuần này'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: _selectedDays,
                items: List.generate(
                  8,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      '$i buổi',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDays = value);
                  }
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                decoration: _inputDecoration(
                  hintText: '',
                  prefixIcon: Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Cảm nhận thể trạng'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedFeeling,
                items: const [
                  DropdownMenuItem(
                    value: 'Khỏe 😊',
                    child: Text(
                      'Khỏe 😊',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Bình thường 😐',
                    child: Text(
                      'Bình thường 😐',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Mệt mỏi 😴',
                    child: Text(
                      'Mệt mỏi 😴',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFeeling = value);
                  }
                },
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
                decoration: _inputDecoration(
                  hintText: '',
                  prefixIcon: Icons.emoji_emotions_outlined,
                ),
              ),
              const SizedBox(height: 14),
              _buildFieldLabel('Lời nhắn / Ghi chú gửi PT', isOptional: true),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textDark,
                ),
                decoration: _inputDecoration(
                  hintText:
                      'Ví dụ: Tuần này em bận đi du lịch nên ăn uống hơi lệch target...',
                  prefixIcon: Icons.chat_bubble_outline_rounded,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'Gửi báo cáo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String label, {
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        if (isOptional)
          Flexible(
            child: Text(
              ' (không bắt buộc)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
          : null,
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _PtTab extends StatefulWidget {
  const _PtTab({
    this.initialReportId,
    this.repository,
    this.reportAnalyticsRepository,
  });

  final String? initialReportId;
  final AdvancedRepository? repository;
  final PlannedVsActualRepository? reportAnalyticsRepository;
  @override
  State<_PtTab> createState() => _PtTabState();
}

class _PtTabState extends State<_PtTab> {
  late final AdvancedRepository repo;
  late final PlannedVsActualRepository reportAnalyticsRepository;
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> proposals = [];
  bool loading = true;
  bool _openedInitialReport = false;

  bool get _isSunday => canCreateWeeklyReportOn(DateTime.now());
  bool get _isThursday => canCreateMidWeekCheckInOn(DateTime.now());

  DateTime get _currentWeekMonday => weeklyReportWeekStart(DateTime.now());

  bool get _hasCurrentWeekReport {
    final weekStart = _currentWeekMonday.toIso8601String().substring(0, 10);
    return rows.any(
      (row) =>
          _v(row, 'requestType').toLowerCase() == 'weeklyreport' &&
          _v(row, 'weekStartDate').startsWith(weekStart),
    );
  }

  bool get _hasMidWeekCheckIn {
    final weekStart = _currentWeekMonday.toIso8601String().substring(0, 10);
    return rows.any(
      (row) =>
          _v(row, 'requestType').toLowerCase() == 'midweekcheckin' &&
          _v(row, 'weekStartDate').startsWith(weekStart),
    );
  }

  Iterable<Map<String, dynamic>> get _reviewRows => rows.where((row) {
    final type = _v(row, 'requestType').toLowerCase();
    return type == 'weeklyreport' || type == 'midweekcheckin';
  });

  @override
  void initState() {
    super.initState();
    repo = widget.repository ?? AdvancedRepository();
    reportAnalyticsRepository =
        widget.reportAnalyticsRepository ?? PlannedVsActualRepository();
    load();
  }

  Future<void> load() async {
    try {
      rows = await repo.ptRequests();
    } catch (_) {
      rows = [];
    }
    try {
      proposals = await repo.myMealPlanProposals();
    } catch (_) {
      proposals = [];
    }
    if (!mounted) return;
    setState(() => loading = false);

    final reportId = widget.initialReportId;
    if (!_openedInitialReport && reportId != null && reportId.isNotEmpty) {
      _openedInitialReport = true;
      final matching = rows.where((row) => _v(row, 'reportId') == reportId);
      if (matching.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showResult(matching.first);
        });
      }
    }
  }

  Future<void> _actionProposal(
    Map<String, dynamic> proposal,
    String action,
  ) async {
    final id = _v(proposal, 'id');
    if (id.isEmpty) return;
    try {
      await repo.actionMealPlanProposal(id, action);
      if (!mounted) return;
      _notice(
        context,
        action == 'apply'
            ? 'Đã áp dụng toàn bộ đề xuất lộ trình.'
            : 'Đã từ chối đề xuất; lộ trình hiện tại được giữ nguyên.',
      );
      await load();
    } catch (error) {
      if (mounted) _notice(context, error);
    }
  }

  Future<Map<String, dynamic>?> _proposalForReport(String reportId) async {
    final matching = proposals.where(
      (proposal) => _v(proposal, 'reviewRequestId') == reportId,
    );
    if (matching.isEmpty) return null;

    final cached = Map<String, dynamic>.from(matching.first);
    final proposalId = _v(cached, 'id');
    if (proposalId.isEmpty) return cached;

    try {
      return await repo.mealPlanProposal(proposalId);
    } catch (_) {
      // The list response already contains items. Keep the detail usable if a
      // refresh request fails temporarily.
      return cached;
    }
  }

  Widget _buildReviewedMealChanges(
    Map<String, dynamic> result,
    Map<String, dynamic>? proposal,
  ) {
    final rawItems = proposal?['items'] ?? proposal?['Items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    if (items.isNotEmpty) {
      items.sort((a, b) {
        final dateCompare = _v(
          a,
          'plannedDate',
        ).compareTo(_v(b, 'plannedDate'));
        if (dateCompare != 0) return dateCompare;
        return _mealOrder(
          _v(a, 'mealType'),
        ).compareTo(_mealOrder(_v(b, 'mealType')));
      });

      final rawSources = proposal?['sourceMeals'] ?? proposal?['SourceMeals'];
      final sourceById = <String, Map<String, dynamic>>{};
      if (rawSources is List) {
        for (final raw in rawSources.whereType<Map>()) {
          final source = Map<String, dynamic>.from(raw);
          final id = _v(source, 'mealPlanItemId');
          if (id.isNotEmpty) sourceById[id] = source;
        }
      }

      final byDate = <String, List<Map<String, dynamic>>>{};
      for (final item in items) {
        final date = _v(item, 'plannedDate');
        (byDate[date] ??= []).add(item);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in byDate.entries)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _proposalDateLabel(entry.key),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < entry.value.length; index++) ...[
                    _buildReviewedMealChange(entry.value[index], sourceById),
                    if (index < entry.value.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    // Compatibility for reports reviewed before meal-plan proposals existed.
    final rawLegacy = result['suggestedChanges'] ?? result['SuggestedChanges'];
    final legacy = rawLegacy is List ? rawLegacy.whereType<Map>().toList() : [];
    if (legacy.isNotEmpty) {
      return Column(
        children: [
          for (final raw in legacy)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                '${_actionLabel(_v(Map<String, dynamic>.from(raw), 'action'))} • '
                '${_mealTypeLabel(_v(Map<String, dynamic>.from(raw), 'mealType'))}',
              ),
              subtitle: Text(
                '${_v(Map<String, dynamic>.from(raw), 'dayOfWeek')}\n'
                '${_v(Map<String, dynamic>.from(raw), 'notes')}',
              ),
            ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'PT không đề xuất thay đổi món ăn cho báo cáo này.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewedMealChange(
    Map<String, dynamic> item,
    Map<String, Map<String, dynamic>> sourceById,
  ) {
    final action = _v(item, 'action').toLowerCase();
    final source = sourceById[_v(item, 'existingMealPlanItemId')];
    final oldName = source == null ? '' : _v(source, 'displayName');
    final newName = _v(item, 'displayName');
    final mealLabel = _mealTypeLabel(_v(item, 'mealType'));
    final calories = _v(item, 'targetCalories');
    final quantity = _v(item, 'quantityG');
    final rawIngredients = item['ingredients'] ?? item['Ingredients'];
    final ingredients = rawIngredients is List
        ? rawIngredients
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList()
        : <Map<String, dynamic>>[];

    final String changeText;
    final IconData icon;
    final Color color;
    final Color bgColor;
    switch (action) {
      case 'replace':
        changeText =
            '${oldName.isEmpty ? 'Món hiện tại' : oldName} → '
            '${newName.isEmpty ? 'Món mới' : newName}';
        icon = Icons.swap_horizontal_circle_outlined;
        color = Colors.orange.shade800;
        bgColor = const Color(0xFFFFFBEB);
        break;
      case 'remove':
        changeText = oldName.isEmpty ? 'Món hiện tại' : oldName;
        icon = Icons.remove_circle_outline_rounded;
        color = Colors.red.shade700;
        bgColor = const Color(0xFFFEF2F2);
        break;
      default:
        changeText = newName.isEmpty ? 'Món mới' : newName;
        icon = Icons.add_circle_outline_rounded;
        color = Colors.green.shade700;
        bgColor = const Color(0xFFF0FDF4);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$mealLabel • ${_actionLabel(action)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    if (calories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${_compactNumber(calories)} kcal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  changeText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (quantity.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Khối lượng: ${_compactNumber(quantity)} g',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '• ${_v(ingredient, 'name')}: '
                        '${_compactNumber(_v(ingredient, 'quantity'))} '
                        '${_v(ingredient, 'unit')}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _mealOrder(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 0;
      case 'lunch':
        return 1;
      case 'dinner':
        return 2;
      default:
        return 3;
    }
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType.toLowerCase()) {
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

  String _actionLabel(String action) {
    switch (action.toLowerCase()) {
      case 'replace':
        return 'Thay món';
      case 'remove':
        return 'Bỏ món';
      default:
        return 'Thêm món';
    }
  }

  String _proposalDateLabel(String rawDate) {
    final date = DateTime.tryParse(rawDate);
    if (date == null) return rawDate;
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ nhật',
    ];
    final formatted =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return '${weekdays[date.weekday - 1]}, $formatted';
  }

  String _compactNumber(String raw) {
    final value = num.tryParse(raw);
    if (value == null || value % 1 != 0) return raw;
    return value.toInt().toString();
  }

  Future<void> create({required bool midWeek}) async {
    final available = midWeek ? _isThursday : _isSunday;
    final alreadyCreated = midWeek ? _hasMidWeekCheckIn : _hasCurrentWeekReport;
    if (!available) {
      _notice(
        context,
        midWeek
            ? 'Báo cáo giữa tuần chỉ mở vào Thứ Năm.'
            : 'Báo cáo cuối tuần chỉ mở vào Chủ nhật.',
      );
      return;
    }
    if (alreadyCreated) {
      _notice(
        context,
        midWeek
            ? 'Bạn đã gửi báo cáo giữa tuần này.'
            : 'Bạn đã gửi báo cáo cuối tuần này.',
      );
      return;
    }

    try {
      final coaches = await repo.myCoaches();
      final hasConnected = coaches.any(
        (c) => _v(c, 'connectionStatus').toLowerCase() == 'connected',
      );
      if (!hasConnected) {
        if (mounted) _notice(context, 'Bạn chưa Đăng ký kết nối với PT');
        return;
      }
    } catch (e) {
      if (mounted) _notice(context, e);
      return;
    }

    if (!mounted) return;
    final monday = _currentWeekMonday;
    final shouldContinue = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WeeklyReportPreviewScreen(
          weekStart: monday,
          repository: reportAnalyticsRepository,
          dataThrough: midWeek ? DateTime.now() : null,
          midWeek: midWeek,
        ),
      ),
    );
    if (!mounted || shouldContinue != true) return;

    final submission = await showDialog<_WeeklyCheckInData>(
      context: context,
      builder: (_) => const _WeeklyCheckInDialog(),
    );
    if (!mounted || submission == null) return;

    try {
      await repo.createPtReport(
        monday.toIso8601String().substring(0, 10),
        7,
        studentNote: submission.note.isEmpty ? null : submission.note,
        checkInWeight: submission.weight,
        checkInBodyFat: submission.bodyFat,
        trainingDaysCount: submission.trainingDays,
        bodyFeeling: submission.feeling,
        requestType: midWeek ? 'MidWeekCheckIn' : 'WeeklyReport',
      );
      if (mounted) {
        _notice(
          context,
          midWeek
              ? 'Đã gửi báo cáo giữa tuần cho PT.'
              : 'Đã gửi báo cáo cuối tuần cho PT.',
        );
      }
      await load();
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showResult(Map<String, dynamic> row) async {
    try {
      final reportId = _v(row, 'reportId');
      final result = await repo.ptResult(reportId);
      final proposal = await _proposalForReport(reportId);
      if (!mounted) return;
      final detailAction = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (detailContext) {
            final studentNote = _v(result, 'studentNote');
            final checkInWeight = _v(result, 'checkInWeight');
            final checkInBodyFat = _v(result, 'checkInBodyFat');
            final trainingDaysCount = _v(result, 'trainingDaysCount');
            final bodyFeeling = _v(result, 'bodyFeeling');
            final isMidWeek =
                _v(result, 'requestType').toLowerCase() == 'midweekcheckin';
            final hasPendingProposal =
                proposal != null &&
                _v(proposal, 'status').toLowerCase() == 'pending';
            final canUseLegacyAction =
                !hasPendingProposal &&
                _v(result, 'status').toLowerCase() == 'reviewed';

            final statusText = _v(result, 'status');

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAF9),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(
                  isMidWeek
                      ? 'Chi tiết đánh giá giữa tuần'
                      : 'Chi tiết đánh giá cuối tuần',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textDark,
                  ),
                  onPressed: () => Navigator.pop(detailContext),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Hero Card: Week Date Range + Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMidWeek
                                          ? 'Báo cáo giữa tuần'
                                          : 'Báo cáo cuối tuần',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _weeklyDateRangeLabel(
                                        _v(result, 'weekStartDate'),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            _buildStatusBadge(statusText),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upper Section: Gymer Check-in Report Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_turned_in_rounded,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Báo cáo check-in của bạn',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Metrics 2x2 Grid Layout
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.monitor_weight_outlined,
                                    label: 'Cân nặng thực tế',
                                    value: checkInWeight.isNotEmpty
                                        ? '$checkInWeight kg'
                                        : 'Chưa nhập',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.pie_chart_outline_rounded,
                                    label: 'Tỷ lệ mỡ cơ thể',
                                    value: checkInBodyFat.isNotEmpty
                                        ? '$checkInBodyFat %'
                                        : 'Chưa nhập',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.fitness_center_rounded,
                                    label: 'Số buổi đã tập',
                                    value: trainingDaysCount.isNotEmpty
                                        ? '$trainingDaysCount buổi'
                                        : 'Chưa nhập',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.sentiment_satisfied_alt_rounded,
                                    label: 'Cảm nhận thể trạng',
                                    value: bodyFeeling.isNotEmpty
                                        ? bodyFeeling
                                        : 'Chưa nhập',
                                  ),
                                ),
                              ],
                            ),
                            if (studentNote.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ghi chú gửi PT:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            studentNote,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              fontSize: 12.5,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lower Section: PT Evaluation & Target Recommendations
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.sports_rounded,
                                    color: Colors.amber.shade900,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Đánh giá & Nhận xét từ PT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // PT Comment Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    size: 20,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _v(
                                        result,
                                        'ptComment',
                                        'Chưa có nhận xét chi tiết từ huấn luyện viên.',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Calo & Protein target badges
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '🔥',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Calo đề xuất',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              _v(
                                                    result,
                                                    'suggestedCalorieTarget',
                                                  ).isNotEmpty
                                                  ? '${_v(result, 'suggestedCalorieTarget')} kcal'
                                                  : '-',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '🥩',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Protein đề xuất',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              _v(
                                                    result,
                                                    'suggestedProteinTarget',
                                                  ).isNotEmpty
                                                  ? '${_v(result, 'suggestedProteinTarget')} g'
                                                  : '-',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Proposal Section
                      Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isMidWeek
                                ? 'Đề xuất điều chỉnh giữa tuần'
                                : 'Lộ trình đề xuất cho tuần kế tiếp',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildReviewedMealChanges(result, proposal),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: hasPendingProposal || canUseLegacyAction
                  ? SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    Navigator.pop(detailContext, 'reject'),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  hasPendingProposal
                                      ? 'Từ chối toàn bộ'
                                      : 'Từ chối',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () =>
                                    Navigator.pop(detailContext, 'apply'),
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  hasPendingProposal
                                      ? 'Áp dụng toàn bộ'
                                      : 'Áp dụng mục tiêu',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      );

      if (!mounted || detailAction == null) return;
      if (proposal != null &&
          _v(proposal, 'status').toLowerCase() == 'pending') {
        await _actionProposal(proposal, detailAction);
        return;
      }

      try {
        await repo.ptAction(reportId, detailAction);
        if (!mounted) return;
        _notice(
          context,
          detailAction == 'apply'
              ? 'Đã áp dụng mục tiêu PT đề xuất.'
              : 'Đã từ chối mục tiêu PT đề xuất.',
        );
        await load();
      } catch (error) {
        if (mounted) _notice(context, error);
      }
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  String _selectedStatusFilter = 'ALL';
  String _selectedTypeFilter = 'ALL';
  int _currentPage = 1;
  static const int _pageSize = 5;

  List<Map<String, dynamic>> get _filteredReviewRows {
    return _reviewRows.where((row) {
      final status = _v(row, 'status').toLowerCase();
      final type = _v(row, 'requestType').toLowerCase();

      bool matchStatus = true;
      if (_selectedStatusFilter == 'PENDING') {
        matchStatus = status == 'pending';
      } else if (_selectedStatusFilter == 'REVIEWED') {
        matchStatus = status == 'reviewed' || status == 'applied';
      } else if (_selectedStatusFilter == 'REJECTED') {
        matchStatus = status == 'rejected';
      }

      bool matchType = true;
      if (_selectedTypeFilter == 'MIDWEEK') {
        matchType = type == 'midweekcheckin';
      } else if (_selectedTypeFilter == 'WEEKLY') {
        matchType = type == 'weeklyreport';
      }

      return matchStatus && matchType;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredReviewRows.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  List<Map<String, dynamic>> get _paginatedReviewRows {
    final filtered = _filteredReviewRows;
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= filtered.length) return [];
    final endIndex = (startIndex + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  void _setStatusFilter(String status) {
    if (_selectedStatusFilter != status) {
      setState(() {
        _selectedStatusFilter = status;
        _currentPage = 1;
      });
    }
  }

  void _setTypeFilter(String type) {
    if (_selectedTypeFilter != type) {
      setState(() {
        _selectedTypeFilter = type;
        _currentPage = 1;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedStatusFilter = 'ALL';
      _selectedTypeFilter = 'ALL';
      _currentPage = 1;
    });
  }

  Widget _buildActionHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.send_and_archive_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạo báo cáo check-in PT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Nhấn chọn để tạo báo cáo chỉ số thực tế gửi PT',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _hasMidWeekCheckIn
                      ? const Color(0xFFF1F5F9)
                      : (_isThursday
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => create(midWeek: true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasMidWeekCheckIn
                              ? const Color(0xFFCBD5E1)
                              : (_isThursday
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0)),
                          width: _isThursday && !_hasMidWeekCheckIn ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _hasMidWeekCheckIn
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                size: 16,
                                color: _hasMidWeekCheckIn
                                    ? Colors.green.shade700
                                    : (_isThursday
                                          ? AppColors.primary
                                          : AppColors.textDark),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _hasMidWeekCheckIn
                                      ? 'Đã gửi giữa tuần'
                                      : (_isThursday
                                            ? 'Tạo báo cáo T5'
                                            : 'Báo cáo giữa tuần'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _hasMidWeekCheckIn
                                        ? Colors.green.shade800
                                        : (_isThursday
                                              ? AppColors.primary
                                              : AppColors.textDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasMidWeekCheckIn
                                ? 'Đã báo cáo (Nhấn xem)'
                                : (_isThursday
                                      ? 'Chạm để tạo báo cáo'
                                      : 'Mở vào Thứ Năm'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: _hasMidWeekCheckIn
                                  ? Colors.green.shade700
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: _hasCurrentWeekReport
                      ? const Color(0xFFF1F5F9)
                      : (_isSunday
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => create(midWeek: false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasCurrentWeekReport
                              ? const Color(0xFFCBD5E1)
                              : (_isSunday
                                    ? Colors.blue.shade600
                                    : const Color(0xFFE2E8F0)),
                          width: _isSunday && !_hasCurrentWeekReport ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _hasCurrentWeekReport
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                size: 16,
                                color: _hasCurrentWeekReport
                                    ? Colors.green.shade700
                                    : (_isSunday
                                          ? Colors.blue.shade700
                                          : AppColors.textDark),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _hasCurrentWeekReport
                                      ? 'Đã gửi cuối tuần'
                                      : (_isSunday
                                            ? 'Tạo báo cáo CN'
                                            : 'Báo cáo cuối tuần'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _hasCurrentWeekReport
                                        ? Colors.green.shade800
                                        : (_isSunday
                                              ? Colors.blue.shade800
                                              : AppColors.textDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasCurrentWeekReport
                                ? 'Đã báo cáo (Nhấn xem)'
                                : (_isSunday
                                      ? 'Chạm để tạo báo cáo'
                                      : 'Mở vào Chủ nhật'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: _hasCurrentWeekReport
                                  ? Colors.green.shade700
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Giữa tuần: PT điều chỉnh T6–CN. Cuối tuần: PT chuẩn bị lộ trình tuần tới.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabelSummary() {
    if (_selectedStatusFilter == 'ALL' && _selectedTypeFilter == 'ALL') {
      return 'Tất cả';
    }
    if (_selectedStatusFilter != 'ALL' && _selectedTypeFilter == 'ALL') {
      switch (_selectedStatusFilter) {
        case 'PENDING':
          return 'Chờ duyệt';
        case 'REVIEWED':
          return 'Đã nhận xét';
        case 'REJECTED':
          return 'Từ chối';
      }
    }
    if (_selectedStatusFilter == 'ALL' && _selectedTypeFilter != 'ALL') {
      switch (_selectedTypeFilter) {
        case 'MIDWEEK':
          return 'Giữa tuần';
        case 'WEEKLY':
          return 'Cuối tuần';
      }
    }
    return 'Đã lọc (2)';
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ duyệt ⏳';
      case 'REVIEWED':
        return 'Đã nhận xét ✅';
      case 'REJECTED':
        return 'Từ chối ❌';
      default:
        return 'Tất cả';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'MIDWEEK':
        return 'Giữa tuần ⏱️';
      case 'WEEKLY':
        return 'Cuối tuần 📅';
      default:
        return 'Tất cả loại';
    }
  }

  void _showFilterBottomSheet() {
    String tempStatus = _selectedStatusFilter;
    String tempType = _selectedTypeFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isTempFiltered = tempStatus != 'ALL' || tempType != 'ALL';

            return Padding(
              padding: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.tune_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Bộ lọc báo cáo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      if (isTempFiltered)
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              tempStatus = 'ALL';
                              tempType = 'ALL';
                            });
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Mặc định (Tất cả)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  const Text(
                    'Trạng thái đánh giá',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBottomSheetChip(
                        label: 'Tất cả',
                        isSelected: tempStatus == 'ALL',
                        onTap: () => setModalState(() => tempStatus = 'ALL'),
                      ),
                      _buildBottomSheetChip(
                        label: 'Chờ duyệt ⏳',
                        isSelected: tempStatus == 'PENDING',
                        onTap: () =>
                            setModalState(() => tempStatus = 'PENDING'),
                      ),
                      _buildBottomSheetChip(
                        label: 'Đã nhận xét ✅',
                        isSelected: tempStatus == 'REVIEWED',
                        onTap: () =>
                            setModalState(() => tempStatus = 'REVIEWED'),
                      ),
                      _buildBottomSheetChip(
                        label: 'Từ chối ❌',
                        isSelected: tempStatus == 'REJECTED',
                        onTap: () =>
                            setModalState(() => tempStatus = 'REJECTED'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Loại báo cáo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBottomSheetChip(
                        label: 'Tất cả loại',
                        isSelected: tempType == 'ALL',
                        onTap: () => setModalState(() => tempType = 'ALL'),
                      ),
                      _buildBottomSheetChip(
                        label: 'Giữa tuần ⏱️',
                        isSelected: tempType == 'MIDWEEK',
                        onTap: () => setModalState(() => tempType = 'MIDWEEK'),
                      ),
                      _buildBottomSheetChip(
                        label: 'Cuối tuần 📅',
                        isSelected: tempType == 'WEEKLY',
                        onTap: () => setModalState(() => tempType = 'WEEKLY'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatusFilter = tempStatus;
                          _selectedTypeFilter = tempType;
                          _currentPage = 1;
                        });
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Áp dụng bộ lọc',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTag(String label, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 3),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(1.0),
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final isFiltered =
        _selectedStatusFilter != 'ALL' || _selectedTypeFilter != 'ALL';
    final totalCount = _reviewRows.length;
    final filteredCount = _filteredReviewRows.length;

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Lịch sử đánh giá',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isFiltered ? '$filteredCount/$totalCount' : '$totalCount',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Material(
                color: isFiltered
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _showFilterBottomSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFiltered
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : const Color(0xFFE2E8F0),
                        width: isFiltered ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 15,
                          color: isFiltered
                              ? AppColors.primary
                              : AppColors.textDark,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getFilterLabelSummary(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isFiltered
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isFiltered
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isFiltered
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isFiltered) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Đang lọc: ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_selectedStatusFilter != 'ALL') ...[
                    _buildActiveTag(
                      _getStatusLabel(_selectedStatusFilter),
                      onRemove: () => _setStatusFilter('ALL'),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_selectedTypeFilter != 'ALL') ...[
                    _buildActiveTag(
                      _getTypeLabel(_selectedTypeFilter),
                      onRemove: () => _setTypeFilter('ALL'),
                    ),
                    const SizedBox(width: 6),
                  ],
                  InkWell(
                    onTap: _resetFilters,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Xóa lọc',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final filtered = _filteredReviewRows;
    if (filtered.isEmpty) return const SizedBox.shrink();

    final totalPages = _totalPages;
    final totalItems = filtered.length;
    final startItem = (_currentPage - 1) * _pageSize + 1;
    final endItem = (_currentPage * _pageSize).clamp(1, totalItems);

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $startItem–$endItem / $totalItems báo cáo',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: AppColors.primary,
                disabledColor: Colors.grey.shade300,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Trang $_currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: AppColors.primary,
                disabledColor: Colors.grey.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;
    switch (status.toLowerCase()) {
      case 'pending':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Chờ duyệt';
        break;
      case 'reviewed':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Đã nhận xét';
        break;
      case 'applied':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Đã áp dụng';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Từ chối';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final paginatedRows = _paginatedReviewRows;
    final totalFiltered = _filteredReviewRows.length;

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _buildActionHeader(),
          _buildFilterSection(),

          if (totalFiltered == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 44,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Không tìm thấy báo cáo phù hợp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thử thay đổi bộ lọc trạng thái hoặc loại báo cáo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Đặt lại bộ lọc'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          for (final r in paginatedRows) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _v(r, 'requestType').toLowerCase() ==
                                              'midweekcheckin'
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _v(r, 'requestType').toLowerCase() ==
                                              'midweekcheckin'
                                          ? 'Giữa tuần'
                                          : 'Báo cáo tuần',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            _v(
                                                  r,
                                                  'requestType',
                                                ).toLowerCase() ==
                                                'midweekcheckin'
                                            ? Colors.green.shade800
                                            : Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _weeklyDateRangeLabel(_v(r, 'weekStartDate')),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(_v(r, 'status')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_v(r, 'checkInWeight').isNotEmpty ||
                        _v(r, 'trainingDaysCount').isNotEmpty ||
                        _v(r, 'bodyFeeling').isNotEmpty ||
                        _v(r, 'studentNote').isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chỉ số check-in của bạn:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                if (_v(r, 'checkInWeight').isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.monitor_weight_outlined,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cân nặng: ${_v(r, 'checkInWeight')} kg${_v(r, 'checkInBodyFat').isNotEmpty ? ' (${_v(r, 'checkInBodyFat')}%)' : ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_v(r, 'trainingDaysCount').isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.fitness_center_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tập: ${_v(r, 'trainingDaysCount')} buổi',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_v(r, 'bodyFeeling').isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.sentiment_satisfied_alt_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Thể trạng: ${_v(r, 'bodyFeeling')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (_v(r, 'studentNote').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Ghi chú: "${_v(r, 'studentNote')}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 11.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (_v(r, 'status').toLowerCase() == 'reviewed' ||
                        _v(r, 'status').toLowerCase() == 'applied') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đánh giá & Mục tiêu từ PT:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• Nhận xét: ${_v(r, 'ptComment', 'Chưa có nhận xét')}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• Calo: ${_v(r, 'suggestedCalorieTarget', '-')} kcal',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '• Protein: ${_v(r, 'suggestedProteinTarget', '-')} g',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else if (_v(r, 'status').toLowerCase() == 'pending') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đang chờ HLV nhận xét và cập nhật mục tiêu mới...',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => showResult(r),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Xem chi tiết'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          _buildPaginationFooter(),
        ],
      ),
    );
  }
}

class _BudgetTab extends StatefulWidget {
  const _BudgetTab();
  @override
  State<_BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<_BudgetTab> {
  final repo = AdvancedRepository();
  final planRepo = MealPlanRepository();
  Map<String, dynamic>? data;
  bool loading = true;
  bool generating = false;
  final amount = TextEditingController(), minutes = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    // Dispose TextEditingController để tránh
    // "dependents.isEmpty is not true" khi TextField con vẫn còn dependent
    // vào controller khi widget unmount.
    amount.dispose();
    minutes.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      data = await repo.budget();
      amount.text = data == null ? '' : _v(data!, 'budgetVnd');
      minutes.text = data == null ? '' : _v(data!, 'timeLimitMin');
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final a = int.tryParse(amount.text), m = int.tryParse(minutes.text);
    if (a == null || m == null) {
      _notice(context, 'Nhập số hợp lệ');
      return;
    }
    try {
      data = await repo.saveBudget(
        id: data == null ? null : _v(data!, 'id'),
        amount: a,
        minutes: m,
      );
      if (mounted) {
        setState(() {});
        _notice(context, 'Đã lưu ngân sách');
      }
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  Future<void> generateLunchboxPlan() async {
    if (data == null) {
      _notice(context, 'Hãy lưu ngân sách trước khi tạo cơm hộp.');
      return;
    }
    setState(() => generating = true);
    try {
      final plan = await planRepo.generateBudgetLunchboxPlan();
      final grocery = await planRepo.getGroceryList(plan.id);
      if (!mounted) return;
      final items = (grocery['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                '${item['name'] ?? item['Name']}: ${item['quantity'] ?? item['Quantity']} ${item['unit'] ?? item['Unit']}',
          )
          .join('\n');
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(plan.title),
          content: SingleChildScrollView(
            child: Text(
              'Danh sách đi chợ\n\n${items.isEmpty ? 'Chưa có nguyên liệu từ recipe của kế hoạch.' : items}\n\nTổng giá ước tính: ${grocery['estimatedTotalVnd'] ?? grocery['EstimatedTotalVnd'] ?? 0}đ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    } finally {
      if (mounted) setState(() => generating = false);
    }
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator())
      : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách (VND)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Thời gian nấu tối đa (phút)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: save,
              child: Text(data == null ? 'Tạo ngân sách' : 'Cập nhật'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: generating ? null : generateLunchboxPlan,
              icon: generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lunch_dining_outlined),
              label: Text(
                generating ? 'Đang tạo...' : 'Tạo kế hoạch cơm hộp Office',
              ),
            ),
            if (data != null)
              TextButton(
                onPressed: () async {
                  await repo.deleteBudget(_v(data!, 'id'));
                  data = null;
                  amount.clear();
                  minutes.clear();
                  if (mounted) setState(() {});
                },
                child: const Text(
                  'Xóa giới hạn',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
}

class _CoachTab extends StatefulWidget {
  const _CoachTab({this.gymerMode = false});

  final bool gymerMode;

  @override
  State<_CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<_CoachTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> connectedCoaches = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      connectedCoaches = await repo.myCoaches();
      rows = await repo.coaches();
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> showCoach(Map<String, dynamic> row) async {
    try {
      final detail = await repo.coach(_v(row, 'id'));
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        showDragHandle: false,
        builder: (_) {
          Map<String, dynamic>? connection;
          for (final coach in connectedCoaches) {
            if (_v(coach, 'id') == _v(detail, 'id')) {
              connection = coach;
              break;
            }
          }
          final connectionStatus = connection == null
              ? ''
              : _v(connection, 'connectionStatus');
          final isConnected = connectionStatus.toLowerCase() == 'connected';
          final isPending = connection != null && !isConnected;
          final isAccessGranted = connection?['isAccessGranted'] == true;

          return _CoachProfileSheet(
            coach: detail,
            isPending: isPending,
            isConnected: isConnected,
            isAccessGranted: isAccessGranted,
            onConnect: () async {
              await repo.connect(_v(detail, 'id'));
              await load();
            },
            onToggleAccess: () async {
              await repo.access(_v(detail, 'id'), !isAccessGranted);
              await load();
            },
          );
        },
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
      : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (!widget.gymerMode)
                Row(
                  children: [
                    Expanded(
                      child: _OutlineChip(
                        label: 'Đăng ký Coach',
                        icon: Icons.verified_user_outlined,
                        onTap: () => Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => const CoachRegisterScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _OutlineChip(
                        label: 'Học viên',
                        icon: Icons.group_outlined,
                        onTap: () => Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => const CoachClientsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (!widget.gymerMode) const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sports_gymnastics_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.gymerMode
                            ? 'Huấn luyện viên phù hợp'
                            : 'Danh bạ coach',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.gymerMode)
                        Text(
                          'Chủ động cấp hoặc thu hồi quyền xem dữ liệu',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Connected section
              if (connectedCoaches.isNotEmpty) ...[
                _SectionLabel(
                  label: 'Đang kết nối',
                  icon: Icons.link_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                for (final r in connectedCoaches)
                  _CoachCard(
                    name: _v(r, 'fullName'),
                    specialty: _v(r, 'specialty'),
                    experienceYears: _v(r, 'experienceYears'),
                    avatarUrl: _v(r, 'avatarUrl'),
                    city: _v(r, 'city'),
                    status: _v(r, 'connectionStatus'),
                    isConnected: true,
                    onTap: () => showCoach(r),
                    onAction: () async {
                      final isConn =
                          _v(r, 'connectionStatus').toLowerCase() ==
                          'connected';
                      final title = isConn ? 'Hủy kết nối' : 'Hủy yêu cầu';
                      final confirm = await showDialog<bool>(
                        context: c,
                        builder: (d) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(title),
                          content: Text(
                            isConn
                                ? 'Bạn có chắc muốn hủy kết nối với huấn luyện viên này?'
                                : 'Bạn có chắc muốn rút lại yêu cầu?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(d, false),
                              child: const Text('Bỏ qua'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(d, true),
                              child: Text(
                                title,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await repo.disconnect(_v(r, 'id'));
                          if (c.mounted) {
                            _notice(
                              c,
                              isConn ? 'Đã hủy kết nối' : 'Đã hủy yêu cầu',
                            );
                            load();
                          }
                        } catch (e) {
                          if (c.mounted) _notice(c, e);
                        }
                      }
                    },
                    actionLabel:
                        _v(r, 'connectionStatus').toLowerCase() == 'connected'
                        ? 'Hủy kết nối'
                        : 'Hủy yêu cầu',
                    actionColor: Colors.red,
                  ),
                const SizedBox(height: 16),
                _SectionLabel(
                  label: 'Khám phá thêm',
                  icon: Icons.explore_rounded,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 10),
              ],

              // Available coaches
              if (rows.isEmpty && connectedCoaches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_gymnastics_rounded,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có huấn luyện viên',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final r in rows)
                  _CoachCard(
                    name: _v(r, 'fullName'),
                    specialty: _v(r, 'specialty'),
                    experienceYears: _v(r, 'experienceYears'),
                    avatarUrl: _v(r, 'avatarUrl'),
                    city: _v(r, 'city'),
                    status: '',
                    isConnected: false,
                    onTap: () => showCoach(r),
                    onAction: () async {
                      try {
                        await repo.connect(_v(r, 'id'));
                        if (c.mounted) {
                          _notice(c, 'Đã gửi yêu cầu kết nối');
                          load();
                        }
                      } catch (e) {
                        if (c.mounted) _notice(c, e);
                      }
                    },
                    actionLabel: 'Kết nối',
                    actionColor: AppColors.primary,
                  ),
            ],
          ),
        );
}

class _IngredientTab extends StatefulWidget {
  const _IngredientTab();
  @override
  State<_IngredientTab> createState() => _IngredientTabState();
}

class _IngredientTabState extends State<_IngredientTab> {
  final repo = AdvancedRepository(),
      search = TextEditingController(),
      category = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool safe = false, loading = false;

  @override
  void dispose() {
    // Dispose TextEditingController để tránh
    // "dependents.isEmpty is not true" khi TextField con vẫn còn dependent
    // vào controller khi widget unmount.
    search.dispose();
    category.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      rows = await repo.ingredients(
        search.text,
        safe,
        category: category.text.trim(),
      );
    } catch (e) {
      if (mounted) _notice(context, e);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext c) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: search,
          onSubmitted: (_) => load(),
          decoration: InputDecoration(
            labelText: 'Tìm nguyên liệu',
            suffixIcon: IconButton(
              onPressed: load,
              icon: const Icon(Icons.search),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          controller: category,
          onSubmitted: (_) => load(),
          decoration: InputDecoration(
            labelText: 'Lọc theo danh mục',
            suffixIcon: IconButton(
              onPressed: load,
              icon: const Icon(Icons.filter_alt_outlined),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      SwitchListTile(
        value: safe,
        onChanged: (v) {
          safe = v;
          load();
        },
        title: const Text('Chỉ hiện nguyên liệu an toàn dị ứng'),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            onPressed: () async {
              final changed = await Navigator.push(
                c,
                MaterialPageRoute(builder: (_) => const IngredientEditScreen()),
              );
              if (changed == true) load();
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm (Admin)'),
          ),
        ),
      ),
      Expanded(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  for (final r in rows)
                    ListTile(
                      onTap: () async {
                        await Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => IngredientDetailScreen(
                              ingredient: r,
                              safe: safe,
                            ),
                          ),
                        );
                        await load();
                      },
                      leading: Icon(
                        _v(r, 'isSafeForUser', 'true') == 'true'
                            ? Icons.verified
                            : Icons.warning,
                        color: _v(r, 'isSafeForUser', 'true') == 'true'
                            ? AppColors.primary
                            : Colors.orange,
                      ),
                      title: Text(_v(r, 'nameVi')),
                      subtitle: Text(
                        '${_v(r, 'category')} • ${_v(r, 'caloriesKcal')} kcal',
                      ),
                    ),
                ],
              ),
      ),
    ],
  );
}

class _UserTab extends StatefulWidget {
  const _UserTab();
  @override
  State<_UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<_UserTab> {
  final repo = AdvancedRepository();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      rows = await repo.users();
      error = null;
    } catch (e) {
      error = null;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext c) => loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: load,
          child: ListView(
            children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(userId: _v(r, 'id')),
                      ),
                    ),
                    title: Text(_v(r, 'fullName')),
                    subtitle: Text('${_v(r, 'email')} • ${_v(r, 'role')}'),
                    leading: Icon(
                      _v(r, 'isActive') == 'true'
                          ? Icons.person
                          : Icons.person_off,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (a) async {
                        try {
                          if (a.startsWith('role:')) {
                            await repo.userAction(
                              _v(r, 'id'),
                              'assign-role',
                              a.substring(5),
                            );
                          } else {
                            await repo.userAction(_v(r, 'id'), a);
                          }
                          await load();
                        } catch (e) {
                          if (c.mounted) _notice(c, e);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'toggle-status',
                          child: Text('Bật/tắt trạng thái'),
                        ),
                        PopupMenuItem(value: 'lock', child: Text('Khóa')),
                        PopupMenuItem(value: 'unlock', child: Text('Mở khóa')),
                        PopupMenuItem(
                          value: 'role:User',
                          child: Text('Gán User'),
                        ),
                        PopupMenuItem(
                          value: 'role:Coach',
                          child: Text('Gán Coach'),
                        ),
                        PopupMenuItem(
                          value: 'role:Admin',
                          child: Text('Gán Admin'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
}

// ─── Helper widgets for _CoachTab ─────────────────────────────────────────────

List<String> _coachStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _coachMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _coachDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return value;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

class _CoachProfileSheet extends StatefulWidget {
  const _CoachProfileSheet({
    required this.coach,
    required this.isPending,
    required this.isConnected,
    required this.isAccessGranted,
    required this.onConnect,
    required this.onToggleAccess,
  });

  final Map<String, dynamic> coach;
  final bool isPending;
  final bool isConnected;
  final bool isAccessGranted;
  final Future<void> Function() onConnect;
  final Future<void> Function() onToggleAccess;

  @override
  State<_CoachProfileSheet> createState() => _CoachProfileSheetState();
}

class _CoachProfileSheetState extends State<_CoachProfileSheet> {
  bool _busy = false;

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _notice(context, successMessage);
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _notice(context, error);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coach = widget.coach;
    final name = _v(coach, 'fullName');
    final avatarUrl = _v(coach, 'avatarUrl');
    final headline = _v(coach, 'headline');
    final specialty = _v(coach, 'specialty');
    final city = _v(coach, 'city');
    final bio = _v(coach, 'bio');
    final achievements = _v(coach, 'achievements');
    final experienceYears = _v(coach, 'experienceYears');
    final languages = _coachStringList(coach['languages']);
    final coachingStyles = _coachStringList(coach['coachingStyles']);
    final clientLevels = _coachStringList(coach['clientLevels']);
    final galleryUrls = _coachStringList(coach['galleryUrls']);
    final certificates = _coachMapList(coach['certificates']);
    final specialties = specialty
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final isVerified = _v(
      coach,
      'applicationStatus',
    ).toLowerCase().contains('approved');

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.68,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F8F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Hồ sơ huấn luyện viên',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      _CoachAvatar(
                                        imageUrl: avatarUrl,
                                        width: 82,
                                        height: 82,
                                        radius: 24,
                                      ),
                                      if (isVerified)
                                        Positioned(
                                          right: -5,
                                          bottom: -5,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.verified_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w800,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          headline.isNotEmpty
                                              ? headline
                                              : specialty,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.35,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (city.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 15,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  city,
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  _CoachProfileMetric(
                                    icon: Icons.workspace_premium_outlined,
                                    value: '$experienceYears năm',
                                    label: 'Kinh nghiệm',
                                  ),
                                  const SizedBox(width: 10),
                                  _CoachProfileMetric(
                                    icon: Icons.translate_rounded,
                                    value: languages.isEmpty
                                        ? 'Đang cập nhật'
                                        : '${languages.length} ngôn ngữ',
                                    label: languages.isEmpty
                                        ? 'Thông tin'
                                        : languages.join(', '),
                                  ),
                                ],
                              ),
                              if (widget.isConnected || widget.isPending) ...[
                                const SizedBox(height: 14),
                                _CoachConnectionBanner(
                                  isConnected: widget.isConnected,
                                  isAccessGranted: widget.isAccessGranted,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachProfileSection(
                            icon: Icons.person_outline_rounded,
                            title: 'Giới thiệu',
                            child: Text(
                              bio,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                        if (specialties.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachProfileSection(
                            icon: Icons.fitness_center_rounded,
                            title: 'Chuyên môn',
                            child: _CoachTagWrap(
                              values: specialties,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                        if (coachingStyles.isNotEmpty ||
                            clientLevels.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachProfileSection(
                            icon: Icons.tune_rounded,
                            title: 'Phương pháp huấn luyện',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (coachingStyles.isNotEmpty) ...[
                                  const _CoachFieldLabel('Phong cách'),
                                  const SizedBox(height: 8),
                                  _CoachTagWrap(
                                    values: coachingStyles,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ],
                                if (coachingStyles.isNotEmpty &&
                                    clientLevels.isNotEmpty)
                                  const SizedBox(height: 16),
                                if (clientLevels.isNotEmpty) ...[
                                  const _CoachFieldLabel('Học viên phù hợp'),
                                  const SizedBox(height: 8),
                                  _CoachTagWrap(
                                    values: clientLevels,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (certificates.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachProfileSection(
                            icon: Icons.verified_user_outlined,
                            title: 'Chứng chỉ chuyên môn',
                            trailing: '${certificates.length} chứng chỉ',
                            child: Column(
                              children: [
                                for (
                                  var index = 0;
                                  index < certificates.length;
                                  index++
                                ) ...[
                                  _CoachCertificateCard(
                                    certificate: certificates[index],
                                  ),
                                  if (index < certificates.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (achievements.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachProfileSection(
                            icon: Icons.emoji_events_outlined,
                            title: 'Thành tích nổi bật',
                            child: Text(
                              achievements,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.55,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                        if (galleryUrls.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _CoachProfileSection(
                            icon: Icons.photo_library_outlined,
                            title: 'Hình ảnh hoạt động',
                            trailing: '${galleryUrls.length} ảnh',
                            child: SizedBox(
                              height: 148,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: galleryUrls.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: SizedBox(
                                      width: 190,
                                      child: Image.network(
                                        galleryUrls[index],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const _CoachImageFallback(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _CoachProfileActionBar(
                  busy: _busy,
                  isPending: widget.isPending,
                  isConnected: widget.isConnected,
                  isAccessGranted: widget.isAccessGranted,
                  onPressed: widget.isPending
                      ? null
                      : () => _runAction(
                          widget.isConnected
                              ? widget.onToggleAccess
                              : widget.onConnect,
                          widget.isConnected
                              ? widget.isAccessGranted
                                    ? 'Đã thu hồi quyền xem dữ liệu'
                                    : 'Đã cấp quyền xem dữ liệu'
                              : 'Đã gửi yêu cầu kết nối',
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String imageUrl;
  final double width, height, radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl.isEmpty
            ? const _CoachImageFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CoachImageFallback(),
              ),
      ),
    );
  }
}

class _CoachImageFallback extends StatelessWidget {
  const _CoachImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF63A985)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.sports_gymnastics_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _CoachProfileMetric extends StatelessWidget {
  const _CoachProfileMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.25,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachConnectionBanner extends StatelessWidget {
  const _CoachConnectionBanner({
    required this.isConnected,
    required this.isAccessGranted,
  });

  final bool isConnected, isAccessGranted;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.primary : const Color(0xFFD97706);
    final label = isConnected
        ? isAccessGranted
              ? 'Đã kết nối • PT được xem tiến độ của bạn'
              : 'Đã kết nối • Chưa cấp quyền xem tiến độ'
        : 'Yêu cầu kết nối đang chờ PT xác nhận';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.link_rounded : Icons.schedule_rounded,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachProfileSection extends StatelessWidget {
  const _CoachProfileSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CoachFieldLabel extends StatelessWidget {
  const _CoachFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _CoachTagWrap extends StatelessWidget {
  const _CoachTagWrap({required this.values, required this.color});

  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CoachCertificateCard extends StatelessWidget {
  const _CoachCertificateCard({required this.certificate});

  final Map<String, dynamic> certificate;

  @override
  Widget build(BuildContext context) {
    final name = _v(certificate, 'name');
    final issuer = _v(certificate, 'issuer');
    final issuedDate = _v(certificate, 'issuedDate');
    final expiryDate = _v(certificate, 'expiryDate');
    final imageUrl = _v(certificate, 'imageUrl');
    final dates = <String>[
      if (issuedDate.isNotEmpty) 'Cấp ${_coachDate(issuedDate)}',
      if (expiryDate.isNotEmpty) 'Hết hạn ${_coachDate(expiryDate)}',
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: imageUrl.isEmpty
                  ? Container(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      child: const Icon(
                        Icons.card_membership_rounded,
                        color: AppColors.primary,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        child: const Icon(
                          Icons.card_membership_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Chứng chỉ chuyên môn' : name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (issuer.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    issuer,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                if (dates.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    dates.join(' • '),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _CoachProfileActionBar extends StatelessWidget {
  const _CoachProfileActionBar({
    required this.busy,
    required this.isPending,
    required this.isConnected,
    required this.isAccessGranted,
    required this.onPressed,
  });

  final bool busy, isPending, isConnected, isAccessGranted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDanger = isConnected && isAccessGranted;
    final label = isPending
        ? 'Đang chờ PT xác nhận'
        : isConnected
        ? isAccessGranted
              ? 'Thu hồi quyền xem tiến độ'
              : 'Cho phép PT xem tiến độ'
        : 'Gửi yêu cầu kết nối';
    final icon = isPending
        ? Icons.schedule_rounded
        : isDanger
        ? Icons.lock_outline_rounded
        : isConnected
        ? Icons.lock_open_rounded
        : Icons.person_add_alt_1_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: isDanger
                ? const Color(0xFFB42318)
                : AppColors.primary,
            disabledBackgroundColor: isPending ? const Color(0xFFE9EEF0) : null,
            disabledForegroundColor: isPending ? Colors.grey.shade600 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.name,
    required this.specialty,
    required this.experienceYears,
    required this.avatarUrl,
    required this.city,
    required this.status,
    required this.isConnected,
    required this.onTap,
    required this.onAction,
    required this.actionLabel,
    required this.actionColor,
  });

  final String name, specialty, experienceYears, avatarUrl, city, status;
  final bool isConnected;
  final VoidCallback onTap, onAction;
  final String actionLabel;
  final Color actionColor;

  @override
  Widget build(BuildContext context) {
    final isConn = status.toLowerCase() == 'connected';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConnected
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _CoachAvatar(
                imageUrl: avatarUrl,
                width: 52,
                height: 52,
                radius: 16,
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isConn
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isConn ? 'Đã kết nối' : 'Chờ duyệt',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isConn
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$experienceYears năm kinh nghiệm',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (city.isNotEmpty) ...[
                          Text(
                            '  •  ',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          Flexible(
                            child: Text(
                              city,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Action button
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: actionColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: actionColor,
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
