import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../gymer/views/gymer_hub_screen.dart';
import 'home_package_card.dart';

class GymerPackageCard extends StatelessWidget {
  const GymerPackageCard({super.key});

  static const _premiumGold = Color(0xFFD4A62A);

  void _open(BuildContext context, [GymerFeature? feature]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GymerHubScreen(openFeature: feature)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomePackageCard(
      title: 'GYMER VIP',
      subtitle: 'Bộ công cụ tập luyện đã kích hoạt',
      statusLabel: 'TRẢ PHÍ',
      statusIcon: Icons.workspace_premium_outlined,
      statusIconColor: _premiumGold,
      headerIcon: Icons.fitness_center_outlined,
      accentColor: AppColors.primary,
      onTap: () => _open(context),
      actions: [
        HomePackageAction(
          icon: Icons.track_changes_outlined,
          label: 'Mục tiêu',
          onTap: () => _open(context, GymerFeature.goals),
        ),
        HomePackageAction(
          icon: Icons.rate_review_outlined,
          label: 'PT Review',
          onTap: () => _open(context, GymerFeature.ptReview),
        ),
        HomePackageAction(
          icon: Icons.sports_gymnastics_outlined,
          label: 'Coach',
          onTap: () => _open(context, GymerFeature.coaches),
        ),
        HomePackageAction(
          icon: Icons.emoji_events_outlined,
          label: 'Lộ trình',
          onTap: () => _open(context, GymerFeature.programs),
        ),
      ],
    );
  }
}
