import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/safety_provider.dart';

/// Consent screen — `2.15 Safety, Trust, Compliance / consent`.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _analytics = true;
  bool _notification = true;
  bool _marketing = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<SafetyProvider>();
      await provider.loadAll();
      if (!mounted) return;
      final current = provider.consent;
      if (current != null && !_initialized) {
        _initialized = true;
        setState(() {
          _analytics = current.analytics;
          _notification = current.notification;
          _marketing = current.marketing;
        });
      } else if (!_initialized) {
        _initialized = true;
      }
    });
  }

  Future<void> _save() async {
    final provider = context.read<SafetyProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.updateConsent(
      analytics: _analytics,
      notification: _notification,
      marketing: _marketing,
    );
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã lưu đồng ý.')));
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Không lưu được đồng ý.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Đồng ý',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: Consumer<SafetyProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Chúng tôi tôn trọng quyền kiểm soát dữ liệu của bạn. '
                        'Bạn có thể bật/tắt các tuỳ chọn sau bất kỳ lúc nào.',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitch(
                        title: 'Phân tích ẩn danh (Analytics)',
                        subtitle:
                            'Giúp chúng tôi cải thiện sản phẩm (không nhận dạng cá nhân).',
                        value: _analytics,
                        onChanged: (v) => setState(() => _analytics = v),
                      ),
                      _buildSwitch(
                        title: 'Thông báo đẩy (Notification)',
                        subtitle:
                            'Nhắc bữa ăn, tập và cập nhật kế hoạch.',
                        value: _notification,
                        onChanged: (v) => setState(() => _notification = v),
                      ),
                      _buildSwitch(
                        title: 'Marketing & khuyến mãi',
                        subtitle:
                            'Gửi ưu đãi, sự kiện, mẹo dinh dưỡng mới.',
                        value: _marketing,
                        onChanged: (v) => setState(() => _marketing = v),
                      ),
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Lưu đồng ý',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.progressBackground),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
