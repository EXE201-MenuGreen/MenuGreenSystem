part of 'office_meal_roadmap.dart';

class _RoadmapDay extends StatelessWidget {
  const _RoadmapDay({
    required this.day,
    required this.index,
    required this.top,
    required this.nodeLeft,
    required this.nodeSize,
    required this.onReplaceMeal,
    required this.onOpenMeal,
    this.replacingItemId,
  });

  final _OfficePlanDay day;
  final int index;
  final double top;
  final double nodeLeft;
  final double nodeSize;
  final ValueChanged<MealPlanItemDetail> onReplaceMeal;
  final ValueChanged<MealPlanItemDetail> onOpenMeal;
  final String? replacingItemId;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: _OfficeMealRoadmap._dayExtent,
      child: Stack(
        children: [
          Positioned(
            left: nodeLeft,
            top: 3,
            width: nodeSize,
            height: nodeSize,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x330F5132),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(day.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _shortDate(day.date),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.totalCalories} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 104,
            left: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE9E2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _RoadmapMealRow(
                    label: 'Bữa trưa',
                    icon: Icons.lunch_dining_outlined,
                    item: day.meal('lunch'),
                    isOfficePriority: true,
                    onReplaceMeal: onReplaceMeal,
                    onOpenMeal: onOpenMeal,
                    replacingItemId: replacingItemId,
                  ),
                  const Divider(height: 1, indent: 58),
                  _RoadmapMealRow(
                    label: 'Bữa sáng',
                    icon: Icons.breakfast_dining_outlined,
                    item: day.meal('breakfast'),
                    onReplaceMeal: onReplaceMeal,
                    onOpenMeal: onOpenMeal,
                    replacingItemId: replacingItemId,
                  ),
                  const Divider(height: 1, indent: 58),
                  _RoadmapMealRow(
                    label: 'Bữa tối',
                    icon: Icons.dinner_dining_outlined,
                    item: day.meal('dinner'),
                    onReplaceMeal: onReplaceMeal,
                    onOpenMeal: onOpenMeal,
                    replacingItemId: replacingItemId,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _weekday(DateTime date) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[date.weekday - 1];
  }

  static String _shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _RoadmapMealRow extends StatelessWidget {
  const _RoadmapMealRow({
    required this.label,
    required this.icon,
    required this.item,
    this.isOfficePriority = false,
    required this.onReplaceMeal,
    required this.onOpenMeal,
    this.replacingItemId,
  });

  final String label;
  final IconData icon;
  final MealPlanItemDetail? item;
  final bool isOfficePriority;
  final ValueChanged<MealPlanItemDetail> onReplaceMeal;
  final ValueChanged<MealPlanItemDetail> onOpenMeal;
  final String? replacingItemId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOfficePriority ? const Color(0xFFF1FAF5) : null,
      child: InkWell(
        onTap: item == null ? null : () => onOpenMeal(item!),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOfficePriority
                      ? const Color(0xFFD8F1E4)
                      : const Color(0xFFF1F4F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isOfficePriority ? AppColors.primary : Colors.black54,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        if (isOfficePriority) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8F1E4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ưu tiên Office',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if ((item?.sourceEntityType ?? '').toLowerCase() ==
                            'aiscan') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8EC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'AI Scan · Đã dùng',
                              style: TextStyle(
                                color: Color(0xFFC23B58),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item?.displayName ?? 'Chưa có món',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item == null ? '--' : '${item!.targetCalories ?? 0} kcal',
                style: TextStyle(
                  color: isOfficePriority ? AppColors.primary : Colors.black54,
                  fontSize: 12,
                  fontWeight: isOfficePriority
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (item != null) ...[
                const SizedBox(width: 2),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Đổi món',
                    onPressed: replacingItemId == null
                        ? () => onReplaceMeal(item!)
                        : null,
                    icon: replacingItemId == item!.id
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.swap_horiz_rounded, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
