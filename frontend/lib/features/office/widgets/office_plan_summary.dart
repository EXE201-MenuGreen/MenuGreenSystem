import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../meal_plan/models/meal_plan_responses.dart';

class OfficeBudgetSummaryCard extends StatelessWidget {
  const OfficeBudgetSummaryCard({
    super.key,
    required this.amount,
    required this.minutes,
    this.plannedCost,
    this.budgetLimit,
    required this.onEdit,
  });

  final String amount;
  final int? minutes;
  final int? plannedCost;
  final int? budgetLimit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDCEFE5),
                foregroundColor: AppColors.primary,
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mục tiêu ngân sách tuần',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$amount · ${minutes == null ? 'Chưa đặt thời gian' : 'Tối đa $minutes phút'}',
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          if (plannedCost != null && budgetLimit != null) ...[
            const SizedBox(height: 14),
            _BudgetUsage(
              plannedCost: plannedCost!,
              budgetLimit: budgetLimit!,
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetUsage extends StatelessWidget {
  const _BudgetUsage({required this.plannedCost, required this.budgetLimit});

  final int plannedCost;
  final int budgetLimit;

  @override
  Widget build(BuildContext context) {
    final exceeded = plannedCost > budgetLimit;
    final difference = (budgetLimit - plannedCost).abs();
    final progress = budgetLimit <= 0
        ? 0.0
        : (plannedCost / budgetLimit).clamp(0.0, 1.0).toDouble();
    final color = exceeded ? Colors.redAccent : AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Chi phí dự kiến',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            Text(
              '${_currency(plannedCost)} / ${_currency(budgetLimit)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: Colors.black12,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          exceeded
              ? 'Vượt ngân sách ${_currency(difference)}'
              : 'Còn lại ${_currency(difference)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  static String _currency(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '${buffer.toString()}đ';
  }
}

class OfficeEmptyPlanCard extends StatelessWidget {
  const OfficeEmptyPlanCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          children: [
            Icon(Icons.lunch_dining_outlined, size: 46, color: AppColors.primary),
            SizedBox(height: 12),
            Text('Chưa có kế hoạch cơm hộp', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Thiết lập ngân sách rồi tạo kế hoạch phù hợp cho tuần làm việc.', textAlign: TextAlign.center),
          ],
        ),
      );
}

class OfficePlanOverview extends StatelessWidget {
  const OfficePlanOverview({super.key, required this.plan});
  final MealPlanDetail plan;

  int get _avgKcalPerMeal {
    if (plan.items.isEmpty) return 0;
    final validKcal = plan.items
        .where((i) => i.targetCalories != null && i.targetCalories! > 0)
        .map((i) => i.targetCalories!)
        .toList();
    if (validKcal.isNotEmpty) {
      return (validKcal.reduce((a, b) => a + b) / validKcal.length).round();
    }
    return plan.totalCalories > 0
        ? (plan.totalCalories / plan.items.length).round()
        : 450;
  }

  int get _avgCostPerMeal {
    if (plan.items.isEmpty) return 0;
    final validPrices = plan.items
        .where((i) => i.estimatedPriceVnd != null && i.estimatedPriceVnd! > 0)
        .map((i) => i.estimatedPriceVnd!)
        .toList();
    if (validPrices.isNotEmpty) {
      return (validPrices.reduce((a, b) => a + b) / validPrices.length).round();
    }
    return 0;
  }

  static String _currency(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '${buffer.toString()}đ';
  }

  @override
  Widget build(BuildContext context) {
    final avgCost = _avgCostPerMeal;
    final avgKcal = _avgKcalPerMeal;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFB8DCCB), width: 0.8),
      ),
      color: const Color(0xFFF8FCFA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (avgCost > 0)
                  _MetricChip(
                    icon: Icons.payments_outlined,
                    text: '~${_currency(avgCost)}/bữa',
                  )
                else if (avgKcal > 0)
                  _MetricChip(
                    icon: Icons.local_fire_department_outlined,
                    text: '~$avgKcal kcal/bữa',
                  ),
                _MetricChip(
                  icon: Icons.restaurant_menu_outlined,
                  text: '${plan.items.length} bữa',
                ),
                _MetricChip(
                  icon: Icons.calendar_today_outlined,
                  text: _dateRange(plan),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateRange(MealPlanDetail plan) {
    String format(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    if (plan.startDate == null) return 'Trong tuần';
    if (plan.endDate == null) return format(plan.startDate!);
    return '${format(plan.startDate!)} - ${format(plan.endDate!)}';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: const Color(0xFFF1FAF5), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: 5), Text(text)],
        ),
      );
}
