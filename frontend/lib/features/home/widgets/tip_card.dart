import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.title,
    required this.description,
    required this.type,
    this.onTap,
    this.onDismiss,
  });

  final String title;
  final String description;
  final TipType type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('$title-$description'),
      direction: onDismiss != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade50,
        child: Icon(Icons.delete_outline, color: Colors.red.shade400),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.progressBackground),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: type.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(type.icon, color: type.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TipType {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;

  const TipType({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
  });

  static const tip = TipType(
    icon: Icons.lightbulb_outline,
    color: Color(0xFFF59E0B),
    bgColor: Color(0xFFFEF3C7),
    label: 'Mẹo',
  );

  static const warning = TipType(
    icon: Icons.warning_amber_outlined,
    color: Color(0xFFEF4444),
    bgColor: Color(0xFFFEE2E2),
    label: 'Cảnh báo',
  );

  static const health = TipType(
    icon: Icons.favorite_outline,
    color: Color(0xFF10B981),
    bgColor: Color(0xFFD1FAE5),
    label: 'Sức khỏe',
  );

  static const promotion = TipType(
    icon: Icons.local_offer_outlined,
    color: Color(0xFF8B5CF6),
    bgColor: Color(0xFFEDE9FE),
    label: 'Khuyến mãi',
  );
}

class TipsSection extends StatelessWidget {
  const TipsSection({
    super.key,
    this.title = 'Xu hướng & Tips',
    required this.items,
    this.onItemTap,
    this.onViewAll,
  });

  final String title;
  final List<TipItem> items;
  final void Function(TipItem item)? onItemTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: const Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
        ),
        ...items.map((item) => TipCard(
              title: item.title,
              description: item.description,
              type: item.type,
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
            )),
      ],
    );
  }
}

class TipItem {
  final String title;
  final String description;
  final TipType type;
  final dynamic data;

  const TipItem({
    required this.title,
    required this.description,
    this.type = TipType.tip,
    this.data,
  });
}
