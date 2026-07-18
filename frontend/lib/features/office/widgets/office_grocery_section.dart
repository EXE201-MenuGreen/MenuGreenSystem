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
    final rawItems = data?['items'] ?? data?['Items'];
    final items = rawItems is List ? rawItems.whereType<Map>().toList() : const <Map>[];
    final totalRaw = data?['estimatedTotalVnd'] ?? data?['EstimatedTotalVnd'];
    final total = totalRaw is num ? totalRaw.round() : int.tryParse('$totalRaw');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
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
                    Text('${items.length} nguyên liệu · Ước tính ${currency(total)}'),
                  ],
                ),
              ),
            ],
          ),
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
        else if (items.isEmpty)
          const _GroceryEmptyState(
            icon: Icons.shopping_basket_outlined,
            message: 'Chưa có nguyên liệu từ công thức của kế hoạch.',
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const Icon(
                      Icons.check_box_outline_blank,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      '${items[index]['name'] ?? items[index]['Name'] ?? 'Nguyên liệu'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '${items[index]['quantity'] ?? items[index]['Quantity'] ?? ''} '
                      '${items[index]['unit'] ?? items[index]['Unit'] ?? ''}',
                    ),
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              ],
            ),
          ),
      ],
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
