import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';

class OfficeGroceryTab extends StatefulWidget {
  const OfficeGroceryTab({
    super.key,
    required this.data,
    required this.currency,
    required this.loading,
    required this.hasPlan,
  });

  final Map<String, dynamic>? data;
  final String Function(int?) currency;
  final bool loading;
  final bool hasPlan;

  @override
  State<OfficeGroceryTab> createState() => _OfficeGroceryTabState();

  static bool _hasScheduledDate(Map day) {
    final raw = day['plannedDate'] ?? day['PlannedDate'];
    if (raw == null) return false;
    final parsed = DateTime.tryParse('$raw');
    return parsed != null;
  }

  static List<Map> _maps(dynamic value) =>
      value is List ? value.whereType<Map>().toList() : const <Map>[];

  static int? _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value');
}

class _OfficeGroceryTabState extends State<OfficeGroceryTab> {
  final Set<String> _checkedKeys = {};

  @override
  void initState() {
    super.initState();
    _loadCheckedState();
  }

  Future<void> _loadCheckedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('office_checked_grocery_items') ?? [];
      if (mounted) {
        setState(() {
          _checkedKeys.addAll(saved);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleItem(String itemKey) async {
    setState(() {
      if (_checkedKeys.contains(itemKey)) {
        _checkedKeys.remove(itemKey);
      } else {
        _checkedKeys.add(itemKey);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'office_checked_grocery_items',
        _checkedKeys.toList(),
      );
    } catch (_) {}
  }

  String _getItemKey(Map group, Map item) {
    final groupDate = group['shoppingDate'] ??
        group['ShoppingDate'] ??
        group['plannedDate'] ??
        group['PlannedDate'] ??
        '';
    final name = item['name'] ??
        item['Name'] ??
        item['ingredientId'] ??
        item['IngredientId'] ??
        '';
    final quantity = item['quantity'] ?? item['Quantity'] ?? '';
    final unit = item['unit'] ?? item['Unit'] ?? '';
    return '$groupDate-$name-$quantity-$unit'.replaceAll(' ', '_');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.black54,
              indicatorColor: AppColors.primary,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Theo ngày'),
                Tab(text: 'Theo lượt mua'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDaysTab(),
                _buildTripsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysTab() {
    final weeklyItems = OfficeGroceryTab._maps(widget.data?['items'] ?? widget.data?['Items']);
    final total = OfficeGroceryTab._integer(
      widget.data?['estimatedTotalVnd'] ?? widget.data?['EstimatedTotalVnd'],
    );
    final apiDays = OfficeGroceryTab._maps(widget.data?['days'] ?? widget.data?['Days']);
    final scheduledDays = apiDays
        .where((day) => OfficeGroceryTab._hasScheduledDate(day))
        .toList(growable: false);
    final displayGroups = scheduledDays.isNotEmpty
        ? scheduledDays
        : apiDays.isNotEmpty
            ? apiDays
            : weeklyItems.isEmpty
                ? const <Map>[]
                : <Map>[
                    {'items': weeklyItems, 'estimatedTotalVnd': total},
                  ];
    final showGroupLabel = scheduledDays.isNotEmpty;
    final tripCountLabel = apiDays.length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _WeeklyGrocerySummary(
          itemCount: weeklyItems.length,
          estimatedTotal: widget.currency(total),
          tripCount: tripCountLabel,
          showGroupLabel: showGroupLabel,
        ),
        const SizedBox(height: 16),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!widget.hasPlan)
          const _GroceryEmptyState(
            icon: Icons.event_note_outlined,
            message: 'Hãy tạo kế hoạch cơm hộp trước để có danh sách đi chợ.',
          )
        else if (displayGroups.isEmpty)
          const _GroceryEmptyState(
            icon: Icons.shopping_basket_outlined,
            message: 'Chưa có nguyên liệu từ công thức của kế hoạch.',
          )
        else
          for (var index = 0; index < displayGroups.length; index++) ...[
            _GroceryGroupCard(
              group: displayGroups[index],
              currency: widget.currency,
              isShoppingTrip: false,
              isLegacyWeeklyList: scheduledDays.isEmpty && apiDays.isEmpty,
              checkedKeys: _checkedKeys,
              onToggleItem: _toggleItem,
              getItemKey: _getItemKey,
            ),
            if (index < displayGroups.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _buildTripsTab() {
    final weeklyItems = OfficeGroceryTab._maps(widget.data?['items'] ?? widget.data?['Items']);
    final total = OfficeGroceryTab._integer(
      widget.data?['estimatedTotalVnd'] ?? widget.data?['estimatedTotalVnd']
      ?? widget.data?['EstimatedTotalVnd'],
    );
    final trips = OfficeGroceryTab._maps(widget.data?['shoppingTrips'] ?? widget.data?['ShoppingTrips']);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _WeeklyGrocerySummary(
          itemCount: weeklyItems.length,
          estimatedTotal: widget.currency(total),
          tripCount: trips.length,
          showGroupLabel: false,
          modeLabel: 'Theo lượt mua',
        ),
        const SizedBox(height: 16),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!widget.hasPlan)
          const _GroceryEmptyState(
            icon: Icons.event_note_outlined,
            message: 'Hãy tạo kế hoạch cơm hộp trước để có danh sách đi chợ.',
          )
        else if (trips.isEmpty)
          const _GroceryEmptyState(
            icon: Icons.storefront_outlined,
            message: 'Chưa có lượt đi chợ — thêm công thức cho từng ngày trong kế hoạch.',
          )
        else
          for (var index = 0; index < trips.length; index++) ...[
            _GroceryGroupCard(
              group: trips[index],
              currency: widget.currency,
              isShoppingTrip: true,
              isLegacyWeeklyList: false,
              checkedKeys: _checkedKeys,
              onToggleItem: _toggleItem,
              getItemKey: _getItemKey,
            ),
            if (index < trips.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _WeeklyGrocerySummary extends StatelessWidget {
  const _WeeklyGrocerySummary({
    required this.itemCount,
    required this.estimatedTotal,
    required this.tripCount,
    this.showGroupLabel = false,
    this.modeLabel = 'Danh sách đi chợ trong tuần',
  });

  final int itemCount;
  final String estimatedTotal;
  final int tripCount;
  final bool showGroupLabel;
  final String modeLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF1FAF5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFB8DCCB)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFD8F1E4),
              foregroundColor: AppColors.primary,
              child: Icon(Icons.shopping_basket_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showGroupLabel ? 'Danh sách đi chợ theo ngày' : modeLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(_summaryText(itemCount, estimatedTotal, tripCount)),
                ],
              ),
            ),
          ],
        ),
      );

  String _summaryText(int itemCount, String estimatedTotal, int tripCount) {
    if (tripCount > 0) {
      return '$tripCount lượt · $itemCount nguyên liệu · Ước tính $estimatedTotal';
    }
    return '$itemCount nguyên liệu · Ước tính $estimatedTotal';
  }
}

class _GroceryGroupCard extends StatelessWidget {
  const _GroceryGroupCard({
    required this.group,
    required this.currency,
    required this.isShoppingTrip,
    required this.isLegacyWeeklyList,
    required this.checkedKeys,
    required this.onToggleItem,
    required this.getItemKey,
  });

  final Map group;
  final String Function(int?) currency;
  final bool isShoppingTrip;
  final bool isLegacyWeeklyList;
  final Set<String> checkedKeys;
  final ValueChanged<String> onToggleItem;
  final String Function(Map group, Map item) getItemKey;

  @override
  Widget build(BuildContext context) {
    final items = OfficeGroceryTab._maps(group['items'] ?? group['Items']);
    final estimatedTotal = OfficeGroceryTab._integer(
      group['estimatedTotalVnd'] ?? group['EstimatedTotalVnd'],
    );
    final date = DateTime.tryParse(
      '${group['shoppingDate'] ?? group['ShoppingDate'] ?? group['plannedDate'] ?? group['PlannedDate'] ?? ''}',
    );
    final coveredMeals = OfficeGroceryTab._maps(
      group['coveredMeals'] ?? group['CoveredMeals'],
    );
    final isInitialTrip =
        group['isInitialTrip'] == true || group['IsInitialTrip'] == true;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5EE),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(date, isInitialTrip),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isShoppingTrip && coveredMeals.isNotEmpty
                            ? _coveredMealsText(coveredMeals)
                            : '${items.length} nguyên liệu cần mua',
                        style: const TextStyle(color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Ước tính',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text(
                      currency(estimatedTotal),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (var index = 0; index < items.length; index++) ...[
            Builder(
              builder: (context) {
                final item = items[index];
                final key = getItemKey(group, item);
                final isChecked = checkedKeys.contains(key);
                return _GroceryItemRow(
                  item: item,
                  currency: currency,
                  isChecked: isChecked,
                  onToggle: () => onToggleItem(key),
                );
              },
            ),
            if (index < items.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  String _title(DateTime? date, bool isInitialTrip) {
    if (isLegacyWeeklyList) return 'Nguyên liệu trong tuần';
    if (!isShoppingTrip) {
      return date == null ? 'Chưa xếp lịch' : _formatDate(date);
    }
    if (isInitialTrip) return 'Mua chuẩn bị trước tuần';
    return 'Mua sau giờ làm ${_formatDate(date)}';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'ngày trong kế hoạch';
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
  }

  static String _coveredMealsText(List<Map> meals) {
    final grouped = <String, List<String>>{};
    for (final meal in meals) {
      final date = DateTime.tryParse(
        '${meal['plannedDate'] ?? meal['PlannedDate'] ?? ''}',
      );
      final dateLabel = date == null
          ? ''
          : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      final type = '${meal['mealType'] ?? meal['MealType'] ?? ''}';
      final label = switch (type.toLowerCase()) {
        'breakfast' => 'sáng',
        'lunch' => 'trưa',
        'dinner' => 'tối',
        _ => 'bữa ăn',
      };
      grouped.putIfAbsent(dateLabel, () => []).add(label);
    }
    final labels = grouped.entries
        .map((entry) => '${entry.value.join(' & ')} ${entry.key}')
        .join(' · ');
    return 'Cho $labels';
  }
}

class _GroceryItemRow extends StatelessWidget {
  const _GroceryItemRow({
    required this.item,
    required this.currency,
    required this.isChecked,
    required this.onToggle,
  });

  final Map item;
  final String Function(int?) currency;
  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final name = item['name'] ?? item['Name'] ?? 'Nguyên liệu';
    final quantity = item['quantity'] ?? item['Quantity'] ?? '';
    final unit = item['unit'] ?? item['Unit'] ?? '';
    final price = OfficeGroceryTab._integer(
      item['estimatedPriceVnd'] ?? item['EstimatedPriceVnd'],
    );
    final isWeeklyStock =
        item['isWeeklyStock'] == true || item['IsWeeklyStock'] == true;

    return InkWell(
      onTap: onToggle,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Icon(
          isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank,
          color: AppColors.primary,
        ),
        title: Text(
          '$name',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isChecked ? Colors.black38 : AppColors.textDark,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: isWeeklyStock
            ? Text(
                'Mua một lần, dùng nhiều ngày',
                style: TextStyle(
                  color: isChecked ? Colors.black26 : AppColors.primary,
                  fontSize: 12,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              )
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$quantity $unit',
              style: TextStyle(
                color: isChecked ? Colors.black38 : AppColors.textDark,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              currency(price),
              style: TextStyle(
                color: isChecked ? Colors.black26 : Colors.black54,
                fontSize: 12,
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroceryEmptyState extends StatelessWidget {
  const _GroceryEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 48, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}
