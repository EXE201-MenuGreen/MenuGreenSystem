import 'package:flutter/material.dart';


class FeedbackButtons extends StatelessWidget {
  const FeedbackButtons({
    super.key,
    this.isLoading = false,
    this.onLike,
    this.onDislike,
  });

  final bool isLoading;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FeedbackButton(
            icon: Icons.thumb_up_outlined,
            label: 'Thích',
            color: Colors.green,
            isLoading: isLoading,
            onTap: onLike,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeedbackButton(
            icon: Icons.thumb_down_outlined,
            label: 'Không thích',
            color: Colors.orange,
            isLoading: isLoading,
            onTap: onDislike,
          ),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackChips extends StatelessWidget {
  const FeedbackChips({
    super.key,
    this.isLiked,
    this.onTap,
  });

  final bool? isLiked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isLiked == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLiked!
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked! ? Icons.thumb_up : Icons.thumb_down,
              size: 16,
              color: isLiked! ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              isLiked! ? 'Thích' : 'Không thích',
              style: TextStyle(
                fontSize: 12,
                color: isLiked! ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
