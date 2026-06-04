import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../repositories/nutrition_tracking_repository.dart';

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.logs,
  });

  final List<WeightLogItem> logs;

  @override
  Widget build(BuildContext context) {
    final points = _sortedPoints(logs);
    if (points.length < 2) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          points.isEmpty
              ? 'Cần ít nhất 2 lần ghi cân để xem biểu đồ.'
              : 'Thêm một lần ghi cân nữa để xem xu hướng.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    final minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final padding = ((maxY - minY) * 0.15).clamp(1.0, 5.0);
    final chartMin = (minY - padding).floorToDouble();
    final chartMax = (maxY + padding).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xu hướng cân nặng',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: chartMin,
              maxY: chartMax,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ((chartMax - chartMin) / 4).clamp(0.5, 10),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.progressBackground,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: points.length <= 7 ? 1 : (points.length / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          points[index].label,
                          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppColors.progressBackground),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) {
                    return touched.map((spot) {
                      final p = points[spot.spotIndex];
                      return LineTooltipItem(
                        '${p.y.toStringAsFixed(1)} kg\n${p.label}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < points.length; i++)
                      FlSpot(i.toDouble(), points[i].y),
                  ],
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_WeightPoint> _sortedPoints(List<WeightLogItem> logs) {
    final sorted = List<WeightLogItem>.from(logs)
      ..sort((a, b) {
        final aTime = a.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.recordedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    return sorted
        .where((l) => l.recordedAt != null)
        .map((l) {
          final at = l.recordedAt!;
          return _WeightPoint(
            y: l.weightKg,
            label: '${at.day}/${at.month}',
          );
        })
        .toList();
  }
}

class _WeightPoint {
  const _WeightPoint({required this.y, required this.label});

  final double y;
  final String label;
}
