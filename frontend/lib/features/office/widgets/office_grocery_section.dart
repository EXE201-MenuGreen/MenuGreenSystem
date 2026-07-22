import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class OfficeGroceryTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final weeklyItems = _maps(data?['items'] ?? data?['Items']);
    final total = _integer(
      data?['estimatedTotalVnd'] ?? data?['EstimatedTotalVnd'],
    );
    final shoppingTrips = _maps(
      data?['shoppingTrips'] ?? data?['ShoppingTrips'],
    );
    final apiDays = _maps(data?['days'] ?? data?['Days']);
    final groups = shoppingTrips.isNotEmpty
        ? shoppingTrips
        : apiDays.isNotEmpty
        ? apiDays
        : weeklyItems.isEmpty
        ? const <Map>[]
        : <Map>[
            {'items': weeklyItems, 'estimatedTotalVnd': total},
          ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _WeeklyGrocerySummary(
          itemCount: weeklyItems.length,
          estimatedTotal: currency(total),
          tripCount: shoppingTrips.isNotEmpty
              ? shoppingTrips.length
              : apiDays.length,
        ),
        const SizedBox(height: 16),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!hasPlan)
          const _GroceryEmptyState(
            icon: Icons.event_note_outlined,
            message: 'Hãy tạo kế hoạch cơm hộp trước để có danh sách đi chợ.',
          )
        else if (groups.isEmpty)
          const _GroceryEmptyState(
            icon: Icons.shopping_basket_outlined,
            message: 'Chưa có nguyên liệu từ công thức của kế hoạch.',
          )
        else
          for (var index = 0; index < groups.length; index++) ...[
            _GroceryGroupCard(
              group: groups[index],
              currency: currency,
              isShoppingTrip: shoppingTrips.isNotEmpty,
              isLegacyWeeklyList: shoppingTrips.isEmpty && apiDays.isEmpty,
            ),
            if (index < groups.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }

  static List<Map> _maps(dynamic value) =>
      value is List ? value.whereType<Map>().toList() : const <Map>[];

  static int? _integer(dynamic value) =>
      value is num ? value.round() : int.tryParse('$value');
}

class _WeeklyGrocerySummary extends StatelessWidget {
  const _WeeklyGrocerySummary({
    required this.itemCount,
    required this.estimatedTotal,
    required this.tripCount,
  });

  final int itemCount;
  final String estimatedTotal;
  final int tripCount;

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
              const Text(
                'Danh sách đi chợ trong tuần',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                tripCount > 0
                    ? '$tripCount lượt mua · $itemCount nguyên liệu · Ước tính $estimatedTotal'
                    : '$itemCount nguyên liệu · Ước tính $estimatedTotal',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GroceryGroupCard extends StatelessWidget {
  const _GroceryGroupCard({
    required this.group,
    required this.currency,
    required this.isShoppingTrip,
    required this.isLegacyWeeklyList,
  });

  final Map group;
  final String Function(int?) currency;
  final bool isShoppingTrip;
  final bool isLegacyWeeklyList;

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
            _GroceryItemRow(item: items[index], currency: currency),
            if (index < items.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  String _title(DateTime? date, bool isInitialTrip) {
    if (isLegacyWeeklyList) return 'Nguyên liệu trong tuần';
    if (!isShoppingTrip) return _formatDate(date);
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
  const _GroceryItemRow({required this.item, required this.currency});

  final Map item;
  final String Function(int?) currency;

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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: const Icon(
        Icons.check_box_outline_blank,
        color: AppColors.primary,
      ),
      title: Text('$name', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: isWeeklyStock
          ? const Text(
              'Mua một lần, dùng nhiều ngày',
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$quantity $unit'),
          const SizedBox(height: 2),
          Text(
            currency(price),
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
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
