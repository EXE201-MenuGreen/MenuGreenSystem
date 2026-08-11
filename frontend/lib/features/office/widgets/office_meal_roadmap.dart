import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/nutrition_format.dart';
import '../../meal_plan/models/meal_plan_responses.dart';

part 'office_roadmap_day.dart';

class OfficeMealRoadmapSection extends StatelessWidget {
  const OfficeMealRoadmapSection({
    super.key,
    required this.plan,
    required this.onReplaceMeal,
    required this.onOpenMeal,
    this.replacingItemId,
  });
  final MealPlanDetail plan;
  final ValueChanged<MealPlanItemDetail> onReplaceMeal;
  final ValueChanged<MealPlanItemDetail> onOpenMeal;
  final String? replacingItemId;

  @override
  Widget build(BuildContext context) {
    final days = _groupByDay(plan.items);
    if (days.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Kế hoạch chưa có món ăn.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lộ trình ăn uống',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hoàn thành từng ngày trong tuần. Bữa trưa được ưu tiên cho lịch làm việc Office.',
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 12),
        _OfficeMealRoadmap(
          days: days,
          onReplaceMeal: onReplaceMeal,
          onOpenMeal: onOpenMeal,
          replacingItemId: replacingItemId,
        ),
      ],
    );
  }

  List<_OfficePlanDay> _groupByDay(List<MealPlanItemDetail> items) {
    final grouped = <DateTime, List<MealPlanItemDetail>>{};
    for (final item in items) {
      final rawDate = item.plannedDate ?? plan.startDate;
      if (rawDate == null) continue;
      final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final dates = grouped.keys.toList()..sort();
    return [
      for (final date in dates)
        _OfficePlanDay(date: date, meals: grouped[date]!),
    ];
  }
}

class _OfficePlanDay {
  const _OfficePlanDay({required this.date, required this.meals});

  final DateTime date;
  final List<MealPlanItemDetail> meals;

  int get totalCalories =>
      meals.fold(0, (total, meal) => total + (meal.targetCalories ?? 0));

  MealPlanItemDetail? meal(String type) {
    for (final item in meals) {
      if ((item.mealType ?? '').toLowerCase() == type) return item;
    }
    return null;
  }
}

class _OfficeMealRoadmap extends StatelessWidget {
  const _OfficeMealRoadmap({
    required this.days,
    required this.onReplaceMeal,
    required this.onOpenMeal,
    this.replacingItemId,
  });

  static const double _dayExtent = 310;
  static const double _nodeSize = 88;
  static const List<double> _nodePositions = [0.18, 0.5, 0.82, 0.5];

  final List<_OfficePlanDay> days;
  final ValueChanged<MealPlanItemDetail> onReplaceMeal;
  final ValueChanged<MealPlanItemDetail> onOpenMeal;
  final String? replacingItemId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: days.length * _dayExtent,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoadmapPathPainter(
                    nodeCount: days.length,
                    dayExtent: _dayExtent,
                    positions: _nodePositions,
                  ),
                ),
              ),
              for (var index = 0; index < days.length; index++)
                _RoadmapDay(
                  day: days[index],
                  index: index,
                  top: index * _dayExtent,
                  nodeLeft:
                      width * _nodePositions[index % _nodePositions.length] -
                      (_nodeSize / 2),
                  nodeSize: _nodeSize,
                  onReplaceMeal: onReplaceMeal,
                  onOpenMeal: onOpenMeal,
                  replacingItemId: replacingItemId,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RoadmapPathPainter extends CustomPainter {
  const _RoadmapPathPainter({
    required this.nodeCount,
    required this.dayExtent,
    required this.positions,
  });

  final int nodeCount;
  final double dayExtent;
  final List<double> positions;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount < 2) return;
    const nodeCenterY = 47.0;
    final path = Path();
    var previousX = size.width * positions.first;
    var previousY = nodeCenterY;
    path.moveTo(previousX, previousY);

    for (var index = 1; index < nodeCount; index++) {
      final x = size.width * positions[index % positions.length];
      final y = index * dayExtent + nodeCenterY;
      final middleY = (previousY + y) / 2;
      path.cubicTo(previousX, middleY, x, middleY, x, y);
      previousX = x;
      previousY = y;
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCDE8DA)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoadmapPathPainter oldDelegate) {
    return oldDelegate.nodeCount != nodeCount ||
        oldDelegate.dayExtent != dayExtent;
  }
}
