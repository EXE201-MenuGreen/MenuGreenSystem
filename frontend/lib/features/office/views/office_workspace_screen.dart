import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../adaptive_reminders/views/adaptive_reminders_screen.dart';
import '../../meal_templates/views/meal_templates_screen.dart';
import '../../tracking/views/ingredient_scan_screen.dart';
import 'office_meal_plan_screen.dart';

class OfficeWorkspaceScreen extends StatelessWidget {
  const OfficeWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = <_OfficeFeature>[
      _OfficeFeature(
        icon: Icons.document_scanner_outlined,
        title: 'Quét nguyên liệu',
        subtitle: 'Nhận diện nguyên liệu và chọn món phù hợp cho bữa trưa',
        screen: const IngredientScanScreen(officeMode: true),
      ),
      _OfficeFeature(
        icon: Icons.notifications_active_outlined,
        title: 'Nhắc nhở văn phòng',
        subtitle: 'Nhắc uống nước, giãn cơ và giờ ăn',
        screen: const AdaptiveRemindersScreen(),
      ),
      _OfficeFeature(
        icon: Icons.lunch_dining_outlined,
        title: 'Kế hoạch cơm hộp',
        subtitle: 'Thiết lập ngân sách và tạo thực đơn tuần',
        screen: const OfficeMealPlanScreen(),
      ),
      _OfficeFeature(
        icon: Icons.bookmark_outline,
        title: 'Mẫu bữa ăn',
        subtitle: 'Lưu món theo bữa sáng, bữa trưa hoặc bữa tối',
        screen: const MealTemplatesScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Không gian Office')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.business_center_outlined, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  'Làm việc khỏe mạnh hơn',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý cơm hộp, thói quen vận động và sức khỏe công sở tại một nơi.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...features.map(
            (feature) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(feature.icon, color: AppColors.primary),
                ),
                title: Text(feature.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(feature.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => feature.screen),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficeFeature {
  const _OfficeFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;
}
