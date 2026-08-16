import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/api_message_translator_fixed.dart';
import '../models/vietnam_local_models.dart';
import '../providers/safety_provider.dart';
import '../widgets/info_card.dart';
import '../widgets/section_header.dart';
import 'consent_screen.dart';
import 'disclaimer_screen.dart';
import 'report_issue_screen.dart';

/// Safety hub — `2.15 Safety, Trust, Compliance`.
class SafetyHubScreen extends StatefulWidget {
  const SafetyHubScreen({super.key});

  @override
  State<SafetyHubScreen> createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bảo mật & Tuân thủ',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Consumer<SafetyProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.loadAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAlertsCard(provider.alerts),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Hành động có sẵn',
                    icon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildActions(context),
                  const SizedBox(height: 16),
                  _buildDataActions(context, provider),
                  const SizedBox(height: 16),
                  if (provider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAlertsCard(SafetyAlerts? alerts) {
    if (alerts == null) return const SizedBox.shrink();
    final level = alerts.riskLevel.toLowerCase();
    final color = switch (level) {
      'high' => const Color(0xFFDC2626),
      'medium' => const Color(0xFFEAB308),
      _ => AppColors.primary,
    };
    final translated = alerts.alerts
        .map(ApiMessageTranslator.translate)
        .toList(growable: false);
    return InfoCard(
      icon: Icons.health_and_safety,
      color: color,
      title: 'Cảnh báo y khoa',
      subtitle:
          'Mức độ rủi ro: ${_riskLabel(level)}'
          '${alerts.bmi != null ? ' • BMI ${alerts.bmi!.toStringAsFixed(1)}' : ''}'
          '${alerts.allergiesCount > 0 ? ' • ${alerts.allergiesCount} dị ứng' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: translated
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $e',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.description_outlined,
          title: 'Miễn trừ trách nhiệm',
          subtitle: 'Đọc giới hạn & điều khoản y tế của MenuGreen',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.policy_outlined,
          title: 'Quản lý đồng ý',
          subtitle: 'Cập nhật đồng ý analytics / thông báo / marketing',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsentScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.bug_report_outlined,
          title: 'Báo cáo sự cố',
          subtitle: 'Gửi phản hồi khi gặp lỗi kỹ thuật',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.progressBackground),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDataActions(BuildContext context, SafetyProvider provider) {
    return InfoCard(
      icon: Icons.account_circle_outlined,
      title: 'Quyền với dữ liệu cá nhân',
      subtitle: 'Theo chính sách Google Play về quyền riêng tư và xóa dữ liệu.',
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await provider.exportData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result.success
                          ? 'Đã chuẩn bị dữ liệu xuất.'
                          : ApiMessageTranslator.translate(result.message),
                    ),
                    backgroundColor: result.success
                        ? AppColors.primary
                        : Colors.red,
                  ),
                );
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Xuất dữ liệu cá nhân'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(context, provider),
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Vô hiệu hoá tài khoản',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tài khoản sẽ được vô hiệu hoá (soft delete) để có thể phục hồi khi cần.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SafetyProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Vô hiệu hoá tài khoản?'),
          content: const Text(
            'Bạn sẽ không thể đăng nhập sau khi vô hiệu hoá. Dữ liệu sẽ được lưu trữ '
            'để có thể khôi phục khi cần. Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Vô hiệu hoá'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await provider.deleteData();
    if (!context.mounted) return;
    if (result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ApiMessageTranslator.translate(result.data)),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ApiMessageTranslator.translate(result.message)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      default:
        return 'Thấp';
    }
  }
}
