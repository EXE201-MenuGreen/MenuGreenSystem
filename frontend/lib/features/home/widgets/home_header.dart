import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../notifications/providers/notification_provider.dart';
import 'icon_button_with_badge.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.userName,
    required this.greeting,
    this.avatarUrl,
    required this.notificationProvider,
    required this.onSearchTap,
    required this.onMapTap,
    required this.onNotificationTap,
  });

  final String userName;
  final String greeting;
  final String? avatarUrl;
  final NotificationProvider notificationProvider;
  final VoidCallback onSearchTap;
  final VoidCallback onMapTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
                Color(0xFF52B788),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 20.5,
              backgroundColor: AppColors.progressBackground,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
              child: hasAvatar
                  ? null
                  : const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting.toUpperCase(),
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: GoogleFonts.beVietnamPro(
                  color: AppColors.textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        IconButtonWithBadge(
          icon: Icons.search_rounded,
          badge: 0,
          onTap: onSearchTap,
        ),
        const SizedBox(width: 8),
        IconButtonWithBadge(icon: Icons.map_rounded, badge: 0, onTap: onMapTap),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: notificationProvider,
          builder: (context, _) {
            final unreadCount = notificationProvider.unreadCount;
            return IconButtonWithBadge(
              icon: Icons.notifications_outlined,
              badge: unreadCount,
              onTap: onNotificationTap,
            );
          },
        ),
      ],
    );
  }
}
