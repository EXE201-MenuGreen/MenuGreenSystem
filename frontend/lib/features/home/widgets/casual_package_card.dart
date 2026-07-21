import 'package:flutter/material.dart';

import '../../casual/views/casual_hub_screen.dart';
import 'home_package_card.dart';

class CasualPackageCard extends StatelessWidget {
  const CasualPackageCard({super.key});

  static const _accent = Color(0xFFE99900);

  void _open(BuildContext context, [CasualFeature? feature]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CasualHubScreen(openFeature: feature)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomePackageCard(
      title: 'CASUAL PLUS',
      subtitle: 'Bộ công cụ ăn uống đơn giản đã sẵn sàng',
      statusLabel: 'ĐÃ KÍCH HOẠT',
      statusIcon: Icons.check_rounded,
      headerIcon: Icons.restaurant_outlined,
      accentColor: _accent,
      onTap: () => _open(context),
      actions: [
        HomePackageAction(
          icon: Icons.casino_outlined,
          label: 'Vòng quay',
          onTap: () => _open(context, CasualFeature.luckyWheel),
        ),
        HomePackageAction(
          icon: Icons.bolt_outlined,
          label: '1 chạm',
          onTap: () => _open(context, CasualFeature.dailyStarter),
        ),
        HomePackageAction(
          icon: Icons.menu_book_outlined,
          label: 'Kiến thức',
          onTap: () => _open(context, CasualFeature.microLearning),
        ),
      ],
    );
  }
}
