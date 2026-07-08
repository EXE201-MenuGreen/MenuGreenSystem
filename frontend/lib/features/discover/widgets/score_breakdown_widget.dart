import 'package:flutter/material.dart';

import '../models/food_models.dart';

class ScoreBreakdownWidget extends StatelessWidget {
  const ScoreBreakdownWidget({
    super.key,
    required this.score,
  });

  final RecommendationScore score;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Điểm phù hợp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildOverallScore(),
              ],
            ),
            const SizedBox(height: 16),
            _buildScoreBar('Calories', score.calorieScore, Colors.orange),
            const SizedBox(height: 12),
            _buildScoreBar('Macros', score.macroScore, Colors.red),
            const SizedBox(height: 12),
            _buildScoreBar('Ngân sách', score.budgetScore, Colors.green),
            const SizedBox(height: 12),
            _buildScoreBar('Dị ứng', score.allergyScore, Colors.purple),
            const SizedBox(height: 12),
            _buildScoreBar('Sở thích', score.preferenceScore, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScore() {
    final overall = score.overallScore;
    Color color;
    if (overall >= 0.8) {
      color = Colors.green;
    } else if (overall >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            overall >= 0.5 ? Icons.check_circle : Icons.warning,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${(overall * 100).round()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double? value, Color color) {
    if (value == null) return const SizedBox.shrink();

    final percentage = (value * 100).clamp(0, 100).round();
    Color barColor;
    if (percentage >= 80) {
      barColor = Colors.green;
    } else if (percentage >= 50) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0, 1),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: barColor,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
