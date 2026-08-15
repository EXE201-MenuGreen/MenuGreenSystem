import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator_fixed.dart';
import '../../../core/utils/meal_schedule_format.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../advanced/repositories/advanced_repository.dart';
import '../../discover/views/food_detail_screen.dart';
import '../../discover/views/recipe_detail_screen.dart';
import '../../meal_plan/repositories/meal_plan_repository.dart';
import '../../tracking/repositories/nutrition_tracking_repository.dart';
import '../utils/personal_program_period.dart';

@visibleForTesting
bool isPersonalProgramMealDateReached(String rawDate, {DateTime? now}) {
  final plannedDate = DateTime.tryParse(rawDate.trim());
  if (plannedDate == null) return false;

  final current = (now ?? DateTime.now()).toLocal();
  final today = DateTime(current.year, current.month, current.day);
  final plannedDay = DateTime(
    plannedDate.year,
    plannedDate.month,
    plannedDate.day,
  );
  return !plannedDay.isAfter(today);
}

/// Detail screen for a PersonalProgram sent by coach ("PT gửi tôi").
class PersonalProgramDetailScreen extends StatefulWidget {
  const PersonalProgramDetailScreen({
    super.key,
    required this.program,
    this.mealPlanRepository,
    this.nutritionTrackingRepository,
  });

  final Map<String, dynamic> program;
  final MealPlanRepository? mealPlanRepository;
  final NutritionTrackingRepository? nutritionTrackingRepository;

  @override
  State<PersonalProgramDetailScreen> createState() =>
      _PersonalProgramDetailScreenState();
}

class _PersonalProgramDetailScreenState
    extends State<PersonalProgramDetailScreen> {
  bool _accepting = false;
  bool _rejecting = false;
  final Map<String, bool> _mealCompletionOverrides = <String, bool>{};
  final Set<String> _updatingMealIds = <String>{};
  late final MealPlanRepository _mealPlanRepository;
  late final NutritionTrackingRepository _nutritionTrackingRepository;

  @override
  void initState() {
    super.initState();
    _mealPlanRepository = widget.mealPlanRepository ?? MealPlanRepository();
    _nutritionTrackingRepository =
        widget.nutritionTrackingRepository ?? NutritionTrackingRepository();
    _syncMealLogCompletionState();
  }

  bool get _isAccepted =>
      _value(widget.program, 'status').trim().toLowerCase() == 'accepted';

  Future<void> _syncMealLogCompletionState() async {
    if (!_isAccepted) return;

    final rawMeals =
        (widget.program['meals'] ?? widget.program['Meals']) as List?;
    if (rawMeals == null || rawMeals.isEmpty) return;

    final mealIdsByDate = <String, Set<String>>{};
    for (final rawMeal in rawMeals.whereType<Map>()) {
      final meal = Map<String, dynamic>.from(rawMeal);
      final mealId = _value(meal, 'id').isNotEmpty
          ? _value(meal, 'id')
          : _value(meal, 'mealId');
      final rawDate = _value(meal, 'plannedDate');
      if (mealId.isEmpty || !isPersonalProgramMealDateReached(rawDate)) {
        continue;
      }
      mealIdsByDate.putIfAbsent(rawDate, () => <String>{}).add(mealId);
    }
    if (mealIdsByDate.isEmpty) return;

    final candidateIds = mealIdsByDate.values.expand((ids) => ids).toSet();
    setState(() => _updatingMealIds.addAll(candidateIds));

    final resolved = <String, bool>{};
    await Future.wait(
      mealIdsByDate.entries.map((entry) async {
        final date = DateTime.tryParse(entry.key);
        if (date == null) return;
        try {
          final summary = await _nutritionTrackingRepository.getDailySummary(
            date,
          );
          final loggedItemIds =
              summary?.mealLogs
                  .map((log) => log.mealPlanItemId)
                  .whereType<String>()
                  .toSet() ??
              <String>{};
          for (final mealId in entry.value) {
            resolved[mealId] = loggedItemIds.contains(mealId);
          }
        } catch (_) {
          // Keep the snapshot state when daily meal logs cannot be refreshed.
        }
      }),
    );

    if (!mounted) return;
    setState(() {
      _mealCompletionOverrides.addAll(resolved);
      _updatingMealIds.removeAll(candidateIds);
    });
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      final id = widget.program['id'].toString();
      await AdvancedRepository().acceptPersonalProgram(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(ApiMessageTranslator.translate(error.toString())),
        ),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _rejecting = true);
    try {
      final id = widget.program['id'].toString();
      await AdvancedRepository().rejectPersonalProgram(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(ApiMessageTranslator.translate(error.toString())),
        ),
      );
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  Future<void> _toggleMeal(String mealKey, String mealId, bool value) async {
    if (mealId.isEmpty || _updatingMealIds.contains(mealId)) return;

    setState(() => _updatingMealIds.add(mealId));
    try {
      await _mealPlanRepository.toggleItem(mealId, value);
      if (!mounted) return;
      setState(() => _mealCompletionOverrides[mealKey] = value);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(ApiMessageTranslator.translate(error.toString())),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingMealIds.remove(mealId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    final status = (p['status'] ?? '').toString().toLowerCase();
    final isPending = status == 'pending';
    final periodLabel = PersonalProgramPeriod.periodLabel(p);
    final durationLabel = PersonalProgramPeriod.durationLabel(p);
    final meals = ((p['meals'] ?? p['Meals']) as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          p['title']?.toString() ?? 'Lộ trình cá nhân từ PT',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hãy kiểm tra kcal và từng món ăn. Khi chấp nhận, cấu hình Ngày/Tuần/Tháng và lộ trình này mới được áp dụng.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF047857),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _Section(
            icon: Icons.assignment_outlined,
            title: 'Tổng quan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Row('Mô tả', () {
                  String descText =
                      p['description']?.toString() ?? '(không có)';
                  final pattern = RegExp(
                    r'từ\s+(\d{2}/\d{2}/\d{4})\s+đến\s+(\d{2}/\d{2}/\d{4})',
                    caseSensitive: false,
                  );
                  return descText.replaceAllMapped(pattern, (match) {
                    final d1 = match.group(1);
                    final d2 = match.group(2);
                    if (d1 == d2) return 'ngày $d1';
                    return match.group(0)!;
                  });
                }()),
                _Row('Loại cấu hình', _planTypeLabel(_value(p, 'planType'))),
                _Row('Thời gian', periodLabel),
                _Row('Thời lượng', durationLabel),
                _Row('Trạng thái', _statusLabel(status)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.track_changes_rounded,
            title: 'Mục tiêu dinh dưỡng',
            child: Column(
              children: [
                _TargetRow(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Calories/ngày',
                  value: '${p['targetCaloriesDaily'] ?? '?'} kcal',
                  color: const Color(0xFFE65100),
                ),
                if (_value(p, 'minCalories').isNotEmpty)
                  _TargetRow(
                    icon: Icons.vertical_align_bottom,
                    label: 'Kcal món tối thiểu',
                    value: '${_value(p, 'minCalories')} kcal',
                    color: const Color(0xFF6D4C41),
                  ),
                if (_value(p, 'maxCalories').isNotEmpty)
                  _TargetRow(
                    icon: Icons.vertical_align_top,
                    label: 'Kcal món tối đa',
                    value: '${_value(p, 'maxCalories')} kcal',
                    color: const Color(0xFFAD1457),
                  ),
                _TargetRow(
                  icon: Icons.fitness_center_rounded,
                  label: 'Protein',
                  value: '${p['targetProteinG'] ?? '?'} g',
                  color: AppColors.primary,
                ),
                _TargetRow(
                  icon: Icons.bakery_dining_rounded,
                  label: 'Carb',
                  value: '${p['targetCarbsG'] ?? '?'} g',
                  color: const Color(0xFF8D6E63),
                ),
                _TargetRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Chất béo',
                  value: '${p['targetFatG'] ?? '?'} g',
                  color: const Color(0xFFFFA000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if ((p['coachComment']?.toString().isNotEmpty ?? false)) ...[
            _Section(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Ghi chú từ PT',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Text(
                  p['coachComment'].toString(),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (meals.isNotEmpty)
            _Section(
              icon: Icons.restaurant_menu_rounded,
              title: 'Bữa ăn và món ăn trong lộ trình',
              child: _MealsByDate(
                meals: meals,
                completionOverrides: _mealCompletionOverrides,
                updatingMealIds: _updatingMealIds,
                allowToggle: _isAccepted,
                onToggleMeal: _toggleMeal,
              ),
            ),
          if (p['acceptedAt'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF047857),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đã chấp nhận lộ trình này vào ${p['acceptedAt']}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _accepting || _rejecting ? null : _reject,
                    child: _rejecting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _accepting || _rejecting ? null : _accept,
                    child: _accepting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Chấp nhận lộ trình',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _statusLabel(String s) {
    return switch (s) {
      'pending' => 'Chờ bạn phản hồi',
      'accepted' => 'Đã chấp nhận',
      'rejected' => 'Đã từ chối',
      _ => s,
    };
  }

  static String _value(Map<String, dynamic> map, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    return (map[key] ?? map[pascal] ?? '').toString();
  }

  static String _planTypeLabel(String value) {
    return switch (value.toLowerCase()) {
      'daily' => 'Ngày',
      'weekly' => 'Tuần',
      'monthly' => 'Tháng',
      _ => value,
    };
  }
}

class _MealsByDate extends StatelessWidget {
  const _MealsByDate({
    required this.meals,
    required this.completionOverrides,
    required this.updatingMealIds,
    required this.allowToggle,
    required this.onToggleMeal,
  });

  final List<Map<String, dynamic>> meals;
  final Map<String, bool> completionOverrides;
  final Set<String> updatingMealIds;
  final bool allowToggle;
  final Function(String mealKey, String mealId, bool value) onToggleMeal;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final meal in meals) {
      final date = _value(meal, 'plannedDate');
      grouped.putIfAbsent(date, () => []).add(meal);
    }
    final entries = grouped.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return Column(
      children: [
        for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) ...[
          Builder(
            builder: (context) {
              final rawDate = entries[entryIndex].key;
              final dayMeals =
                  List<Map<String, dynamic>>.from(entries[entryIndex].value)
                    ..sort(
                      (a, b) => _mealTypeRank(
                        _value(a, 'mealType'),
                      ).compareTo(_mealTypeRank(_value(b, 'mealType'))),
                    );
              final isToday = _isToday(rawDate);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : Colors.grey.shade200,
                    width: isToday ? 1.2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: entryIndex == 0 || isToday,
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Text(
                          _displayDate(rawDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: const Text(
                              'Hôm nay',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${dayMeals.length} món',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ),
                      for (var idx = 0; idx < dayMeals.length; idx++) ...[
                        _PersonalMealTile(
                          meal: dayMeals[idx],
                          mealIndex: idx,
                          rawDate: rawDate,
                          completionOverrides: completionOverrides,
                          updatingMealIds: updatingMealIds,
                          allowToggle: allowToggle,
                          onToggleMeal: onToggleMeal,
                        ),
                        if (idx < dayMeals.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  static int _mealTypeRank(String mealType) {
    final t = mealType.trim().toLowerCase();
    if (t == 'breakfast' || t.contains('sáng')) return 1;
    if (t == 'lunch' || t.contains('trưa')) return 2;
    if (t == 'dinner' || t.contains('tối')) return 3;
    if (t == 'snack' || t.contains('phụ')) return 4;
    return 5;
  }

  static String _value(Map<String, dynamic> map, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    return (map[key] ?? map[pascal] ?? '').toString();
  }

  static bool _isToday(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day;
  }

  static String _displayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final weekdayStr = switch (parsed.weekday) {
      DateTime.monday => 'Thứ Hai',
      DateTime.tuesday => 'Thứ Ba',
      DateTime.wednesday => 'Thứ Tư',
      DateTime.thursday => 'Thứ Năm',
      DateTime.friday => 'Thứ Sáu',
      DateTime.saturday => 'Thứ Bảy',
      DateTime.sunday => 'Chủ Nhật',
      _ => '',
    };
    return '$weekdayStr, ${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}

class _PersonalMealTile extends StatelessWidget {
  const _PersonalMealTile({
    required this.meal,
    required this.mealIndex,
    required this.rawDate,
    required this.completionOverrides,
    required this.updatingMealIds,
    required this.allowToggle,
    required this.onToggleMeal,
  });

  final Map<String, dynamic> meal;
  final int mealIndex;
  final String rawDate;
  final Map<String, bool> completionOverrides;
  final Set<String> updatingMealIds;
  final bool allowToggle;
  final Function(String mealKey, String mealId, bool value) onToggleMeal;

  @override
  Widget build(BuildContext context) {
    final mealId = _value(meal, 'id').isNotEmpty
        ? _value(meal, 'id')
        : _value(meal, 'mealId');
    final mealName = _mealName(meal);
    final mealKey = mealId.isNotEmpty
        ? mealId
        : '${rawDate}_${mealIndex}_$mealName';

    final isCompletedInMap =
        meal['isCompleted'] == true ||
        _value(meal, 'isCompleted').toLowerCase() == 'true';
    final isCompleted = completionOverrides[mealKey] ?? isCompletedInMap;
    final isUpdating = updatingMealIds.contains(mealId);
    final hasReachedPlannedDate = isPersonalProgramMealDateReached(rawDate);
    final canToggle =
        allowToggle &&
        mealId.isNotEmpty &&
        hasReachedPlannedDate &&
        !isUpdating;

    final mealType = _value(meal, 'mealType');
    final (bgColor, textColor, borderColor) = _mealTypeColors(mealType);
    final calories = _value(meal, 'targetCalories').isEmpty
        ? '0'
        : _value(meal, 'targetCalories');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        dense: true,
        onTap: () => _openDetail(context, meal),
        title: Text(
          mealName,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isCompleted ? Colors.grey.shade500 : const Color(0xFF111827),
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Text(
                      _mealTypeLabel(mealType),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Giờ ăn: ${mealScheduledTimeLabel(_value(meal, 'scheduledTime'), mealType: mealType)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${_nutrition(meal)}\nChạm để xem công thức',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFFEA580C),
                ),
                const SizedBox(width: 3),
                Text(
                  '$calories kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (isUpdating)
              const SizedBox(
                width: 28,
                height: 28,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Tooltip(
                message: !allowToggle
                    ? 'Chấp nhận lộ trình trước khi ghi nhận món ăn'
                    : mealId.isEmpty
                    ? 'Món ăn chưa có dữ liệu để ghi nhận'
                    : !hasReachedPlannedDate
                    ? 'Không thể đánh dấu món ăn trong tương lai'
                    : (isCompleted ? 'Đã ăn' : 'Đánh dấu đã ăn'),
                child: Checkbox(
                  value: isCompleted,
                  onChanged: !canToggle
                      ? null
                      : (val) {
                          if (val != null) {
                            onToggleMeal(mealKey, mealId, val);
                          }
                        },
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _mealName(Map<String, dynamic> meal) {
    final food = _value(meal, 'foodName');
    if (food.isNotEmpty) return food;
    final recipe = _value(meal, 'recipeName');
    return recipe.isEmpty ? 'Món ăn' : recipe;
  }

  static String _nutrition(Map<String, dynamic> meal) {
    return formatNutritionFacts(
      quantityG: _nullableNumber(_value(meal, 'quantityG')),
      caloriesKcal: _nullableNumber(_value(meal, 'targetCalories')),
      proteinG: _nullableNumber(_value(meal, 'proteinG')),
      carbsG: _nullableNumber(_value(meal, 'carbsG')),
      fatG: _nullableNumber(_value(meal, 'fatG')),
    );
  }

  static double? _nullableNumber(String value) =>
      value.isEmpty ? null : double.tryParse(value);

  static (Color, Color, Color) _mealTypeColors(String type) {
    return switch (type.trim().toLowerCase()) {
      'breakfast' => (
        const Color(0xFFFFF7ED),
        const Color(0xFFEA580C),
        const Color(0xFFFFEDD5),
      ),
      'lunch' => (
        const Color(0xFFECFDF5),
        const Color(0xFF059669),
        const Color(0xFFA7F3D0),
      ),
      'dinner' => (
        const Color(0xFFEFF6FF),
        const Color(0xFF2563EB),
        const Color(0xFFBFDBFE),
      ),
      'snack' => (
        const Color(0xFFF5F3FF),
        const Color(0xFF7C3AED),
        const Color(0xFFDDD6FE),
      ),
      _ => (
        const Color(0xFFF3F4F6),
        AppColors.textSecondary,
        const Color(0xFFE5E7EB),
      ),
    };
  }

  static String _mealTypeLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'breakfast' => 'Bữa sáng',
      'lunch' => 'Bữa trưa',
      'dinner' => 'Bữa tối',
      'snack' => 'Bữa phụ',
      _ => value,
    };
  }

  static void _openDetail(BuildContext context, Map<String, dynamic> meal) {
    final foodId = _value(meal, 'foodId');
    final recipeId = _value(meal, 'recipeId');
    final plannedQuantityG = _nullableNumber(_value(meal, 'quantityG'));
    final Widget? screen = foodId.isNotEmpty
        ? FoodDetailScreen(foodId: foodId, plannedQuantityG: plannedQuantityG)
        : recipeId.isNotEmpty
        ? RecipeDetailScreen(
            recipeId: recipeId,
            plannedQuantityG: plannedQuantityG,
          )
        : null;
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  static String _value(Map<String, dynamic> map, String key) {
    final pascal = '${key[0].toUpperCase()}${key.substring(1)}';
    return (map[key] ?? map[pascal] ?? '').toString();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.icon});
  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(không có)' : value,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
