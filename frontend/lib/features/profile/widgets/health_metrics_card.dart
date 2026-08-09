import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HealthMetricsCard extends StatelessWidget {
  const HealthMetricsCard({
    super.key,
    required this.data,
    this.compact = false,
  });

  final Map<String, dynamic>? data;
  final bool compact;

  num? _number(String camelCase, String pascalCase) {
    final value = data?[camelCase] ?? data?[pascalCase];
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  String _decimal(String camelCase, String pascalCase) {
    final value = _number(camelCase, pascalCase);
    if (value == null) return '—';
    return value.toStringAsFixed(1);
  }

  String _integer(String camelCase, String pascalCase) {
    final value = _number(camelCase, pascalCase);
    if (value == null) return '—';
    return value.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final hasMetrics =
        _number('bmi', 'Bmi') != null ||
        _number('bmrKcal', 'BmrKcal') != null ||
        _number('tdeeKcal', 'TdeeKcal') != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chỉ số sức khỏe ước tính',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tính từ chiều cao, cân nặng, tuổi, giới tính, mức hoạt động và mục tiêu.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (!hasMetrics)
            const Text(
              'Hãy hoàn thiện thông tin và lưu thay đổi để hệ thống tính các chỉ số.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'BMI',
                    value: _decimal('bmi', 'Bmi'),
                    unit: 'kg/m²',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'BMR',
                    value: _integer('bmrKcal', 'BmrKcal'),
                    unit: 'kcal/ngày',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'TDEE',
                    value: _integer('tdeeKcal', 'TdeeKcal'),
                    unit: 'kcal/ngày',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: 'Mục tiêu calo',
                    value: _integer('targetCalories', 'TargetCalories'),
                    unit: 'kcal/ngày',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MacroValue(
                      label: 'Protein',
                      value: _integer('targetProteinG', 'TargetProteinG'),
                    ),
                  ),
                  Expanded(
                    child: _MacroValue(
                      label: 'Carb',
                      value: _integer('targetCarbsG', 'TargetCarbsG'),
                    ),
                  ),
                  Expanded(
                    child: _MacroValue(
                      label: 'Chất béo',
                      value: _integer('targetFatG', 'TargetFatG'),
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
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '$value g',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
