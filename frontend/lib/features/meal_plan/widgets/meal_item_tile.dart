import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../models/meal_plan_requests.dart';
import '../models/meal_plan_responses.dart';

/// Swipeable meal item tile widget
/// Inspired by iOS native swipe actions and Lose It! design
class MealItemTile extends StatelessWidget {
  const MealItemTile({
    super.key,
    required this.item,
    this.onTap,
    this.onLog,
    this.onConvertToLog,
    this.onEdit,
    this.onDelete,
    this.onSkip,
    this.onSwap,
    this.showActions = true,
  });

  final MealPlanItemDetail item;
  final VoidCallback? onTap;
  final VoidCallback? onLog;
  final VoidCallback? onConvertToLog;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSkip;
  final VoidCallback? onSwap;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (!showActions) {
      return _buildTile(context);
    }

    return Dismissible(
      key: Key(item.id),
      direction: _getDismissDirection(),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Mark done
          onLog?.call();
          return false; // Don't dismiss, just trigger action
        } else if (direction == DismissDirection.endToStart) {
          // Show skip options
          final result = await _showSkipOptions(context);
          if (result == 'skip') {
            onSkip?.call();
          } else if (result == 'delete') {
            onDelete?.call();
          }
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(
        color: Colors.green,
        icon: Icons.check_circle,
        label: 'Hoàn thành',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.orange,
        icon: Icons.remove_circle,
        label: 'Bỏ qua',
        alignment: Alignment.centerRight,
      ),
      child: _buildTile(context),
    );
  }

  DismissDirection _getDismissDirection() {
    if (item.isDone) {
      return DismissDirection.none; // Don't allow swipe on completed items
    }
    return DismissDirection.horizontal;
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white),
              ],
      ),
    );
  }

  Widget _buildTile(BuildContext context) {
    final mealType = MealType.fromString(item.mealType);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Meal type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    mealType.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${item.targetCalories ?? 0} kcal',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (item.scheduledTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatTime(item.scheduledTime!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status indicator
              _buildStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (item.isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 14),
            SizedBox(width: 4),
            Text(
              'Đã ăn',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onLog != null)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onLog?.call();
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            tooltip: 'Hoàn thành',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (onEdit != null || onSwap != null) ...[
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) {
              HapticFeedback.lightImpact();
              switch (value) {
                case 'edit':
                  onEdit?.call();
                  break;
                case 'swap':
                  onSwap?.call();
                  break;
                case 'skip':
                  onSkip?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
            itemBuilder: (context) => [
              if (onSwap != null)
                const PopupMenuItem(
                  value: 'swap',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 18),
                      SizedBox(width: 8),
                      Text('Đổi món'),
                    ],
                  ),
                ),
              if (onEdit != null)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
              if (onSkip != null)
                const PopupMenuItem(
                  value: 'skip',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Bỏ qua', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    if (item.isDone) return Colors.green;
    if (item.status == 'skipped') return Colors.orange;
    return AppColors.primary;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            if (!item.isDone)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Hoàn thành'),
                subtitle: const Text('Đánh dấu đã ăn'),
                onTap: () => Navigator.pop(context, 'done'),
              ),
            ListTile(
              leading: const Icon(Icons.restaurant, color: AppColors.primary),
              title: const Text('Ghi nhận ăn uống'),
              subtitle: const Text('Chuyển thành bản ghi dinh dưỡng'),
              onTap: () => Navigator.pop(context, 'log'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Sửa'),
              subtitle: const Text('Thay đổi thông tin'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
              title: const Text('Bỏ qua bữa này'),
              subtitle: const Text('Đánh dấu là skipped'),
              onTap: () => Navigator.pop(context, 'skip'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa khỏi kế hoạch'),
              subtitle: const Text('Xóa vĩnh viễn'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ).then((result) {
      if (result == null) return;
      switch (result) {
        case 'done':
          onLog?.call();
          break;
        case 'log':
          onConvertToLog?.call();
          break;
        case 'edit':
          onEdit?.call();
          break;
        case 'skip':
          onSkip?.call();
          break;
        case 'delete':
          onDelete?.call();
          break;
      }
    });
  }

  Future<String?> _showSkipOptions(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.progressBackground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn hành động',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
              title: const Text('Bỏ qua bữa này'),
              subtitle: const Text('Đánh dấu là skipped'),
              onTap: () => Navigator.pop(context, 'skip'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa khỏi kế hoạch'),
              subtitle: const Text('Xóa vĩnh viễn'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Planned meal card - hiển thị bữa ăn trong kế hoạch
class PlannedMealCard extends StatelessWidget {
  const PlannedMealCard({
    super.key,
    required this.mealType,
    required this.items,
    this.onAddItem,
    this.onTapItem,
    this.onLogAll,
    this.onMarkItemDone,
    this.onConvertToLog,
    this.onEditItem,
    this.onDeleteItem,
    this.onSkipItem,
    this.isExpanded = true,
  });

  final MealType mealType;
  final List<MealPlanItemDetail> items;
  final VoidCallback? onAddItem;
  final Function(MealPlanItemDetail)? onTapItem;
  final VoidCallback? onLogAll;
  final Function(MealPlanItemDetail)? onMarkItemDone;
  final Function(MealPlanItemDetail)? onConvertToLog;
  final Function(MealPlanItemDetail)? onEditItem;
  final Function(MealPlanItemDetail)? onDeleteItem;
  final Function(MealPlanItemDetail)? onSkipItem;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final completedCount = items.where((i) => i.isDone).length;
    final totalCount = items.length;
    final allCompleted = totalCount > 0 && completedCount == totalCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: allCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.progressBackground,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: onAddItem,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (allCompleted ? Colors.green : AppColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        mealType.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealType.labelVi,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          allCompleted
                              ? '✓ Đã hoàn thành'
                              : '$completedCount/$totalCount bữa',
                          style: TextStyle(
                            fontSize: 12,
                            color: allCompleted ? Colors.green : AppColors.textSecondary,
                            fontWeight: allCompleted ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!allCompleted && onLogAll != null && items.isNotEmpty)
                    TextButton(
                      onPressed: onLogAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Log tất cả',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  IconButton(
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    tooltip: 'Thêm món',
                  ),
                ],
              ),
            ),
          ),
          // Items
          if (items.isNotEmpty) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final item = items[index];
                return MealItemTile(
                  item: item,
                  onTap: () => onTapItem?.call(item),
                  onLog: () => onMarkItemDone?.call(item),
                  onConvertToLog: () => onConvertToLog?.call(item),
                  onEdit: () => onEditItem?.call(item),
                  onDelete: () => onDeleteItem?.call(item),
                  onSkip: () => onSkipItem?.call(item),
                );
              },
            ),
          ],
          // Empty state
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Chưa có bữa ăn nào',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
