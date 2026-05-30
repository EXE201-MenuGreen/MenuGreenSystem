import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../data/history_mock_data.dart';
import '../models/history_models.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  DateTime _focusedMonth = DateTime(2023, 10, 1);
  DateTime _selectedDate = DateTime(2023, 10, 5);
  String _searchQuery = '';
  MealCategory? _mealFilter;

  static const _monthNames = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  List<HistoryTimelineSection> get _sections {
    var sections = HistoryMockData.sectionsForDate(_selectedDate);

    if (_mealFilter != null) {
      sections = sections.where((s) => s.category == _mealFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      sections = sections
          .map((section) {
            final meals = section.meals
                .where((m) => m.title.toLowerCase().contains(q))
                .toList();
            if (meals.isEmpty) return null;
            return HistoryTimelineSection(
              category: section.category,
              time: section.time,
              meals: meals,
              isHighlighted: section.isHighlighted,
            );
          })
          .whereType<HistoryTimelineSection>()
          .toList();
    }

    return sections;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 24),
                  if (sections.isEmpty)
                    _buildEmptyState()
                  else
                    ...sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      final isLast = index == sections.length - 1;
                      return _TimelineSectionWidget(
                        section: section,
                        showLineBelow: !isLast,
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lịch sử hoạt động',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppColors.textDark),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leadingEmpty = firstWeekday % 7;
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.textDark),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.textDark),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (d) => SizedBox(
                  width: 36,
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: leadingEmpty + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              final day = daysInPrevMonth - leadingEmpty + index + 1;
              return _CalendarDayCell(
                day: day,
                isOutsideMonth: true,
                isSelected: false,
                onTap: () {},
              );
            }

            final day = index - leadingEmpty + 1;
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final isSelected = DateUtils.isSameDay(date, _selectedDate);

            return _CalendarDayCell(
              day: day,
              isOutsideMonth: false,
              isSelected: isSelected,
              onTap: () => _selectDate(date),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.progressBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm món ăn...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tất cả',
            isSelected: _mealFilter == null,
            showDropdown: false,
            onTap: () => setState(() => _mealFilter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.breakfast.filterLabel,
            isSelected: _mealFilter == MealCategory.breakfast,
            showDropdown: true,
            onTap: () => setState(() => _mealFilter = MealCategory.breakfast),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.lunch.filterLabel,
            isSelected: _mealFilter == MealCategory.lunch,
            showDropdown: true,
            onTap: () => setState(() => _mealFilter = MealCategory.lunch),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: MealCategory.snack.filterLabel,
            isSelected: _mealFilter == MealCategory.snack,
            showDropdown: true,
            onTap: () => setState(() => _mealFilter = MealCategory.snack),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.restaurant_menu, size: 48, color: AppColors.textLight.withOpacity(0.8)),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'Không tìm thấy món ăn' : 'Chưa có hoạt động trong ngày này',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isOutsideMonth,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final bool isOutsideMonth;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOutsideMonth ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isOutsideMonth
                    ? AppColors.textLight
                    : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.showDropdown,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool showDropdown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.progressBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            if (showDropdown) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineSectionWidget extends StatelessWidget {
  const _TimelineSectionWidget({
    required this.section,
    required this.showLineBelow,
  });

  final HistoryTimelineSection section;
  final bool showLineBelow;

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = section.isHighlighted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: highlighted ? AppColors.primary : AppColors.progressBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    section.category.icon,
                    size: 20,
                    color: highlighted ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.progressBackground,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        section.category.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        _formatTime(section.time),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...section.meals.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MealCard(meal: meal),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final HistoryMealEntry meal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.progressBackground),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: meal.imageUrl != null
                    ? Image.network(
                        meal.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.calories} kcal • ${meal.portion}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.progressBackground,
      child: const Icon(Icons.restaurant, color: AppColors.textLight, size: 24),
    );
  }
}
