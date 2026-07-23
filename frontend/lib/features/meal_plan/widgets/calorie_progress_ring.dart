import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Widget hiển thị progress calories dạng ring
/// Inspired by MyFitnessPal calorie ring design
class CalorieProgressRing extends StatefulWidget {
  const CalorieProgressRing({
    super.key,
    required this.current,
    required this.target,
    this.size = 80,
    this.strokeWidth = 8,
    this.label = 'kcal',
    this.showPercent = true,
    this.animated = true,
    this.color,
  });

  final int current;
  final int target;
  final double size;
  final double strokeWidth;
  final String label;
  final bool showPercent;
  final bool animated;
  final Color? color;

  @override
  State<CalorieProgressRing> createState() => _CalorieProgressRingState();
}

class _CalorieProgressRingState extends State<CalorieProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _setupAnimation();
    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  void _setupAnimation() {
    _animation = Tween<double>(
      begin: 0,
      end: _progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(CalorieProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current ||
        oldWidget.target != widget.target) {
      _setupAnimation();
      if (widget.animated) {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _progress {
    if (widget.target == 0) return 0;
    return (widget.current / widget.target).clamp(0, 1.5);
  }

  Color get _progressColor {
    if (widget.color != null) return widget.color!;
    final percent = _progress;
    if (percent > 1.0) return Colors.red;
    if (percent >= 0.9) return AppColors.primary;
    if (percent >= 0.7) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    progress: 1.0,
                    color: AppColors.progressBackground,
                    strokeWidth: widget.strokeWidth,
                  ),
                ),
                // Progress ring
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    progress: _animation.value.clamp(0, 1.0),
                    color: _progressColor,
                    strokeWidth: widget.strokeWidth,
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.current.toString(),
                      style: TextStyle(
                        fontSize: widget.size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: widget.size * 0.12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (widget.showPercent)
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: widget.size * 0.12,
                          fontWeight: FontWeight.w600,
                          color: _progressColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2; // Start from top

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Macro progress bar widget
class MacroProgressBar extends StatelessWidget {
  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.unit = 'g',
    this.color,
    this.height = 8,
  });

  final String label;
  final int current;
  final int target;
  final String unit;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$current / $target $unit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.progressBackground,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}

/// Today calories summary card
class TodayCaloriesCard extends StatelessWidget {
  const TodayCaloriesCard({
    super.key,
    required this.current,
    required this.target,
    this.protein = 0,
    this.proteinTarget = 0,
    this.carbs = 0,
    this.carbsTarget = 0,
    this.fat = 0,
    this.fatTarget = 0,
    this.completedMeals = 0,
    this.totalMeals = 0,
    this.onTap,
  });

  final int current;
  final int target;
  final int protein;
  final int proteinTarget;
  final int carbs;
  final int carbsTarget;
  final int fat;
  final int fatTarget;
  final int completedMeals;
  final int totalMeals;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = target - current;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.progressBackground.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.progressBackground, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DINH DƯỠNG HÔM NAY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      if (totalMeals > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '$completedMeals/$totalMeals món đã ăn',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CalorieProgressRing(
                  current: current,
                  target: target,
                  size: 100,
                  strokeWidth: 10,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MacroChip(
                        label: 'PROTEIN',
                        current: protein,
                        target: proteinTarget,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _MacroChip(
                        label: 'CARBS',
                        current: carbs,
                        target: carbsTarget,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _MacroChip(
                        label: 'FAT',
                        current: fat,
                        target: fatTarget,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: remaining >= 0
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    remaining >= 0 ? 'Còn lại' : 'Vượt quá',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${remaining.abs()} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: remaining >= 0 ? AppColors.primary : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            if (totalMeals > 0) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tick món đã ăn để cập nhật các chỉ số thực tế.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final int current;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${current}g / ${target}g',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Streak display widget
class StreakWidget extends StatelessWidget {
  const StreakWidget({
    super.key,
    required this.currentStreak,
    this.longestStreak = 0,
    this.size = 'medium',
  });

  final int currentStreak;
  final int longestStreak;
  final String size;

  @override
  Widget build(BuildContext context) {
    final isSmall = size == 'small';
    final iconSize = isSmall ? 16.0 : 24.0;
    final fontSize = isSmall ? 14.0 : 18.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange.shade700,
            size: iconSize,
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            '$currentStreak ngày',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          if (!isSmall && longestStreak > currentStreak) ...[
            const SizedBox(width: 8),
            Text(
              '(max: $longestStreak)',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
